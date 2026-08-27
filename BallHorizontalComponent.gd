# ==============================================================================
# FC《热血足球》普通足球水平物理组件（现代 float 接口）
#
# 对外只使用十进制 float / Vector2，例如：
#   horizontal_position = Vector2(500.0, 190.0)
#   horizontal_velocity = Vector2(8.0, 0.0)
#
# 为保留原版正负取整差异，减速计算内部临时换算到 1/256 步数，
# 完成原版整数运算后立即转回 float。业务层无需接触原始整数。
# 速度算法和坐标步进彼此分离：
#   - 操控、触地、摩擦函数只负责修改 horizontal_velocity。
#   - step_position() 是唯一更新 horizontal_position 的函数。
# 所有更新单位均为一个“足球逻辑步”，不要乘 delta。
# ==============================================================================
extends Node
class_name BallHorizontalComponent3


enum GroundType {
	GRASS,
	TYPE_1, ## 准确名称尚未确认
	MUD,
	SAND,
}

enum DecayProfile {
	ROLLING = 0, ## 球已经贴地滚动时，每个足球逻辑步使用。
	LANDING = 1, ## 球从空中碰到地面的瞬间使用；每次反弹触地都算一次。
}


const SUBPIXEL: float = 1.0 / 256.0
## 动作 $05 阶段按住“上/下”时，每个足球逻辑步给 VY 增减0.5。
const STEERING_STEP: float = 0.5
## 进入低速区后，一次减速调用固定向0靠近0.0625。
const LOW_SPEED_DECAY: float = 0.0625

## ROM $95EB 参数在普通滚动路径中的现代具名表示。
## 每一行对应一种地面，每行都是：[干球, 湿球]。
## 表值表示高速损耗比例，但计算时仍需按原版要求分项取整。
const ROLLING_DECAY_TABLE: Array = [
	[0.09375, 0.1875], # 草地
	[0.0625,  0.09375], # 类型1
	[0.09375, 0.125],   # 泥地
	[0.09375, 0.1875],  # 沙地
]

## ROM $95EB 参数在普通触地路径中的现代具名表示。
## 每一行对应一种地面，每行都是：[干球, 湿球]。
const LANDING_DECAY_TABLE: Array = [
	[0.09375, 0.1875], # 草地
	[0.0625,  0.09375], # 类型1
	[0.09375, 0.125],   # 泥地
	[0.1875,  0.1875],  # 沙地
]

## 上面两个表与 ROM 原始扁平表的关系：
##   ROLLING 使用原表 pair 0~3；LANDING 使用 pair 3~6。
## 将它们拆开只是为了让现代业务代码易读，没有改变任何参数。
##
## 例如草地滚动：[0.09375, 0.1875]：
##   干草地高速损耗约为速度的 3/32；湿球约为 3/16。
##
## 注意：这些数值不是让代码简单执行 velocity *= (1.0 - coefficient)。
## 原版会对组成比例的每一项分别向下取整；该规则由
## _calculate_signed_loss() 用现代十进制除法和 floor 实现。


signal horizontal_changed(position: Vector2, velocity: Vector2)
signal horizontal_landed(velocity_before: Vector2, velocity_after: Vector2)
signal horizontal_stopped


@export_group("视觉/坐标同步")
## 可不填写。填写足球的 Node2D 后，组件会自动把计算出的 X/Y 写入其 position。
## 若主足球脚本自己负责写坐标，可保持为空，只读取 horizontal_position。
@export var target_node: Node2D

@export_group("FC 地面参数")
## 选择球当前接触的地面；它会决定触地和滚动采用哪组衰减参数。
@export var ground_type: GroundType = GroundType.GRASS
## false=干球；true=湿球。湿球通常采用更大的速度损耗。
@export var wet_ball: bool = false

@export_group("数据观测 / 调试")
@export var debug_observation: bool = false
@export var debug_print_every_step: bool = true
@export var debug_label: String = "ball_xy"


## 现代十进制水平坐标和速度，均量化到 1/256。
## 示例：Vector2(500.0, 190.0)。这里是球在地面平面上的 X/Y，和 Z 高度无关。
var horizontal_position: Vector2 = Vector2.ZERO
## 示例：Vector2(8.0, 0.0) 表示每个足球逻辑步向右移动8、Y方向不动。
var horizontal_velocity: Vector2 = Vector2.ZERO

## true 仅表示组件最近进入了滚动处理；外部仍应结合 ZAxisComponent 判断空中/地面。
var is_rolling: bool = false
## 只用于调试打印编号，不参与物理计算。
var _logic_step: int = 0


func _ready() -> void:
	# 如果绑定了视觉节点，就把节点当前坐标作为物理初始坐标。
	# 这样把组件挂到已有足球节点时，不会在 ready 后突然跳到(0,0)。
	if target_node:
		horizontal_position = _quantize_vector(target_node.position)
	_sync_target()


# ==============================================================================
# 公共接口
# ==============================================================================
func set_horizontal_position(value: Vector2) -> void:
	# 所有外部输入都会自动对齐到FC的1/256网格。
	horizontal_position = _quantize_vector(value)
	_sync_and_emit()


func set_horizontal_velocity(value: Vector2) -> void:
	# 可直接传现代小数，例如 Vector2(8.0, -3.5)。
	horizontal_velocity = _quantize_vector(value)
	_sync_and_emit()


## 起球时不清除当前位置，只设置水平初速度。
## 对应测试样本可调用 launch(Vector2(8.0, 0.0))。
func launch(initial_velocity: Vector2) -> void:
	horizontal_velocity = _quantize_vector(initial_velocity)
	is_rolling = false
	_logic_step = 0
	_sync_and_emit()
	_debug_event("LAUNCH", "velocity=%s" % _format_vector(horizontal_velocity))


# ==============================================================================
# 空中运动与动作 $05 操控
# ==============================================================================
## steering_y：-1=上，0=无，+1=下。
## steering_enabled 只应在球动作低7位为 $05 时传 true。
## 本函数只计算速度，不更新坐标。
##
## 普通飞行、不允许玩家调方向时：process_air_velocity()
## 动作$05且按住上时：process_air_velocity(-1, true)
## 动作$05且按住下时：process_air_velocity(1, true)
## 调用后再统一调用 step_position()。
func process_air_velocity(steering_y: int = 0, steering_enabled: bool = false) -> void:
	var velocity_before := horizontal_velocity

	if steering_enabled and steering_y != 0:
		# 上键每步-0.5，下键每步+0.5；松开后速度保持，不自动回中。
		horizontal_velocity.y = _quantize(
			horizontal_velocity.y + signi(steering_y) * STEERING_STEP
		)

	is_rolling = false
	_sync_and_emit()
	_debug_velocity_change(
		"AIR_VELOCITY",
		velocity_before,
		"steering_y=%d enabled=%s" % [steering_y, str(steering_enabled)]
	)


## 只施加动作 $05 的上下操控，不积分坐标。
## 这是方便外部状态机直接调用的别名；正常循环也可使用 process_air_velocity()。
func apply_action_05_steering(direction_y: int) -> void:
	if direction_y == 0:
		return
	var before := horizontal_velocity
	horizontal_velocity.y = _quantize(
		horizontal_velocity.y + signi(direction_y) * STEERING_STEP
	)
	_sync_and_emit()
	_debug_event(
		"STEER",
		"before=%s direction_y=%d after=%s" % [
			_format_vector(before), direction_y, _format_vector(horizontal_velocity)
		]
	)


# ==============================================================================
# 触地与滚动
# ==============================================================================
## 每次普通触地调用一次。只改变水平速度，不重复积分坐标。
## 推荐连接 ZAxisComponent.landed 信号。足球每一次反弹碰地都必须调用，
## 不能只在最后一次停止弹跳时调用。
func apply_landing_decay() -> void:
	var before := horizontal_velocity
	var coefficient := _get_decay_coefficient(DecayProfile.LANDING)
	horizontal_velocity = _decay_vector_once(horizontal_velocity, coefficient)
	is_rolling = true
	_sync_and_emit()
	horizontal_landed.emit(before, horizontal_velocity)
	_debug_event(
		"LANDING_DECAY",
		"coefficient=%.6f before=%s after=%s" % [
			coefficient, _format_vector(before), _format_vector(horizontal_velocity)
		]
	)


## 计算地面滚动时下一个水平速度，但不更新坐标。
## 顺序：满足共同低速条件时额外减速一次 -> 固定减速一次。
## 调用后由外部统一调用 step_position()。
func process_rolling_velocity() -> void:
	var velocity_before := horizontal_velocity
	var coefficient := _get_decay_coefficient(DecayProfile.ROLLING)
	var extra_low_speed_call := (
		_is_low_speed_component(horizontal_velocity.x)
		and _is_low_speed_component(horizontal_velocity.y)
	)

	# 原版特殊低速规则：只有X和Y两个分量都进入低速范围，才额外调用一次。
	# 所以两个分量都很小时，每逻辑步总共减速两次；若只有Y很小而X仍很快，
	# Y也只减速一次。这一点已由斜向CSV验证。
	if extra_low_speed_call:
		horizontal_velocity = _decay_vector_once(horizontal_velocity, coefficient)

	# 不管是否低速，每个滚动逻辑步至少都会执行这一轮减速。
	horizontal_velocity = _decay_vector_once(horizontal_velocity, coefficient)
	is_rolling = not horizontal_velocity.is_zero_approx()
	_sync_and_emit()
	_debug_velocity_change(
		"ROLL_VELOCITY",
		velocity_before,
		"coefficient=%.6f extra_low_speed_call=%s" % [
			coefficient, str(extra_low_speed_call)
		]
	)

	if horizontal_velocity == Vector2.ZERO:
		horizontal_stopped.emit()
		_debug_event("STOP", "position=%s" % _format_vector(horizontal_position))


## 唯一负责更新水平坐标的公共步进函数。
## 它不计算摩擦、不处理按键，只执行：position += velocity。
##
## 空中调用顺序：
##   process_air_velocity(...)
##   step_position("AIR")
##
## 地面滚动调用顺序：
##   process_rolling_velocity()
##   step_position("ROLL")
##
## 触地瞬间 apply_landing_decay() 只改变速度，不额外调用本函数，
## 因为该逻辑步的坐标已经由此前的空中步进更新过。
func step_position(phase: String = "MOVE") -> void:
	_logic_step += 1
	var position_before := horizontal_position
	horizontal_position = _quantize_vector(
		horizontal_position + horizontal_velocity
	)
	_sync_and_emit()
	_debug_position_step(phase, position_before)


func stop_immediately() -> void:
	# 供出界、进球、守门员接住等外部事件强制清除水平速度。
	horizontal_velocity = Vector2.ZERO
	is_rolling = false
	_sync_and_emit()
	horizontal_stopped.emit()
	_debug_event("FORCED_STOP", "position=%s" % _format_vector(horizontal_position))


# ==============================================================================
# 现代 float 衰减；仅保留原版要求的取整时机
# ==============================================================================
func _decay_vector_once(value: Vector2, coefficient: float) -> Vector2:
	return Vector2(
		_decay_component_once(value.x, coefficient),
		_decay_component_once(value.y, coefficient)
	)


func _decay_component_once(value: float, coefficient: float) -> float:
	var quantized_value := _quantize(value)

	# 原版由速度高字节选择低速分支。
	# 准确十进制范围：-1.0 <= V <= 0.99609375。
	# 因为速度已量化到1/256，所以现代写法 -1.0 <= V < 1.0 与原版完全等价。
	if quantized_value >= -1.0 and quantized_value < 1.0:
		# 低速不读取比例参数，使用现代move_toward固定向0靠近0.0625。
		# 若本滚动步触发双调用，总变化就是0.125。
		return _quantize(move_toward(quantized_value, 0.0, LOW_SPEED_DECAY))

	# 高速读取表，并用现代十进制公式计算损耗。
	var signed_loss := _calculate_signed_loss(quantized_value, coefficient)
	return _quantize(quantized_value - signed_loss)


## 用现代十进制除法计算高速损耗，同时保留原版每一项分别取整的时机。
## _floor_to_subpixel() 等价于“向负无穷方向对齐到1/256网格”，因此负速度
## 仍会得到与6502算术右移一致的非对称结果。
func _calculate_signed_loss(value: float, coefficient: float) -> float:
	if is_equal_approx(coefficient, 0.0625): # 1/16
		return _floor_to_subpixel(value / 16.0)
	if is_equal_approx(coefficient, 0.09375): # 1/16 + 1/32
		return (
			_floor_to_subpixel(value / 16.0)
			+ _floor_to_subpixel(value / 32.0)
		)
	if is_equal_approx(coefficient, 0.125): # 1/8
		return _floor_to_subpixel(value / 8.0)
	if is_equal_approx(coefficient, 0.1875): # 1/8 + 1/16
		return (
			_floor_to_subpixel(value / 8.0)
			+ _floor_to_subpixel(value / 16.0)
		)
	if is_equal_approx(coefficient, 0.25): # 1/4
		return _floor_to_subpixel(value / 4.0)

	push_error("未支持的水平衰减参数：%.6f" % coefficient)
	return 0.0


func _is_low_speed_component(value: float) -> bool:
	# 现代float判定。先量化，避免外部传入0.9999999之类的浮点噪声。
	# 原版区间略微不对称：-1.0算低速，正1.0不算。
	# 在1/256网格上，V < 1.0 的最大正值自然就是0.99609375。
	var quantized_value := _quantize(value)
	return quantized_value >= -1.0 and quantized_value < 1.0


func _get_decay_coefficient(profile: DecayProfile) -> float:
	# 干球取每行第0个值，湿球取第1个值。
	var wet_index := 1 if wet_ball else 0
	var ground_index := int(ground_type) & 3
	if profile == DecayProfile.LANDING:
		return LANDING_DECAY_TABLE[ground_index][wet_index]
	return ROLLING_DECAY_TABLE[ground_index][wet_index]


func _quantize(value: float) -> float:
	# 1/256是二进制浮点可以精确表示的数，不会产生0.1那类循环小数误差。
	return float(roundi(value / SUBPIXEL)) * SUBPIXEL


## 向负无穷方向量化到1/256，用于模拟原版算术右移的取整方向。
## 普通状态写回仍使用上面的round量化；只有衰减公式的分项损耗使用floor。
func _floor_to_subpixel(value: float) -> float:
	return floor(value / SUBPIXEL) * SUBPIXEL


func _quantize_vector(value: Vector2) -> Vector2:
	return Vector2(_quantize(value.x), _quantize(value.y))


# ==============================================================================
# 显示与十进制调试
# ==============================================================================
func _sync_target() -> void:
	if target_node:
		target_node.position = horizontal_position


func _sync_and_emit() -> void:
	_sync_target()
	horizontal_changed.emit(horizontal_position, horizontal_velocity)


func _debug_velocity_change(
	phase: String,
	velocity_before: Vector2,
	detail: String
) -> void:
	if not debug_observation or not debug_print_every_step:
		return
	print((
		"[%s] next_step=%d phase=%s | velocity %s -> %s | %s"
	) % [
		debug_label, _logic_step + 1, phase,
		_format_vector(velocity_before), _format_vector(horizontal_velocity), detail
	])


func _debug_position_step(phase: String, position_before: Vector2) -> void:
	if not debug_observation or not debug_print_every_step:
		return
	print((
		"[%s] step=%d phase=%s_POSITION | position %s -> %s | velocity=%s"
	) % [
		debug_label, _logic_step, phase,
		_format_vector(position_before), _format_vector(horizontal_position),
		_format_vector(horizontal_velocity)
	])


func _debug_event(event_name: String, detail: String) -> void:
	if not debug_observation:
		return
	print("[%s] EVENT %s | %s" % [debug_label, event_name, detail])


func _format_vector(value: Vector2) -> String:
	return "(x=%.6f, y=%.6f)" % [value.x, value.y]
