# ==============================================================================
# FC《热血足球》普通足球水平物理组件
# ==============================================================================
#
# 作用：
#   负责普通足球在 XY 平面上的：
#
#   1. 水平位置
#   2. 水平速度
#   3. 空中动作 $05 的上下微调
#   4. 足球每次触地时的水平速度衰减
#   5. 足球落地滚动后的持续减速
#   6. 将一个 FC Logic Tick 的位移拆成 3 个 Godot Physics Frame
#
#
# ------------------------------------------------------------------------------
# 数据精度
# ------------------------------------------------------------------------------
#
# 内部所有位置、速度、衰减参数都使用 1/256 定点精度：
#
#   1.0      = 256 raw
#   0.5      = 128 raw
#   0.25     = 64 raw
#   0.0625   = 16 raw
#
# 例如：
#
#   horizontal_velocity_raw.x = 2048
#
# 表示：
#
#   2048 / 256 = 8.0
#
#
# ------------------------------------------------------------------------------
# 对外接口
# ------------------------------------------------------------------------------
#
# 外部业务层仍然使用普通 Vector2 / float：
#
#   set_horizontal_position(Vector2(500.0, 190.0))
#   set_horizontal_velocity(Vector2(8.0, 0.0))
#
# 只有组件内部接触 raw。
#
#
# ------------------------------------------------------------------------------
# 时间单位
# ------------------------------------------------------------------------------
#
# FC 物理规则以 Logic Tick 为单位。
#
# 不使用 delta：
#
#   ❌ velocity * delta
#   ❌ friction * delta
#
# 当前一个 Logic Tick 被平滑拆成：
#
#   3 个 Godot Physics Frame
#
# 但 3 帧结束后的最终 raw 坐标仍然与一次 FC Tick 完全一致。
#
#
# ------------------------------------------------------------------------------
# 水平速度与坐标职责
# ------------------------------------------------------------------------------
#
# process_air_velocity()
# apply_landing_decay()
# process_rolling_velocity()
#
# 这些函数只负责修改速度。
#
# step_logic_tick()
#
# 锁定本 Logic Tick 要移动的总位移。
#
# _physics_process()
#
# 再把这一整 Tick 的位移分成 3 个 Physics Frame 实际移动。
#
# ==============================================================================
extends Node
class_name BallHorizontalComponent
# ==============================================================================
# 类型
# ==============================================================================
enum GroundType {
	GRASS,
	TYPE_1, ## 准确地面名称尚未确认。
	MUD,
	SAND,
}
enum DecayProfile {
	## 足球已经完全进入地面滚动阶段时使用。
	ROLLING,
	## 足球从空中碰到地面的瞬间使用。
	##
	## 注意：
	## 每一次弹跳重新碰地都属于一次 LANDING。
	LANDING,
}
# ==============================================================================
# 基础定点常量
# ==============================================================================
## FC 水平物理使用 1/256 精度。
const RAW_ONE: int = 256
## 一个 Logic Tick 被拆成多少个 Godot Physics Frame。
##
## 当前：
##
##   1 Logic Tick = 3 Physics Frame
const PHYSICS_FRAMES_PER_LOGIC_TICK: int = 3
# ==============================================================================
# 动作 $05 空中操控参数
# ==============================================================================
## 动作 $05 中按住上 / 下时，每个 Logic Tick 修改的 Y 速度。
##
## 原十进制：
##
##   0.5
##
## raw：
##
##   0.5 × 256 = 128
const STEERING_STEP_RAW: int = 128
# ==============================================================================
# 低速衰减参数
# ==============================================================================
## 足球进入低速分支以后，每次衰减调用固定向 0 靠近：
##
##   0.0625
##
## raw：
##
##   0.0625 × 256 = 16
const LOW_SPEED_DECAY_RAW: int = 16
# ==============================================================================
# 高速衰减参数
# ==============================================================================
#
# 这些值不是“直接减去多少 raw”。
#
# 它们只是用 raw 整数表示原版的比例参数：
#
#   16 raw = 0.0625  = 1/16
#   24 raw = 0.09375 = 1/16 + 1/32
#   32 raw = 0.125   = 1/8
#   48 raw = 0.1875  = 1/8 + 1/16
#   64 raw = 0.25    = 1/4
#
# 实际损耗仍然由 _calculate_signed_loss_raw() 按原版移位方式计算。
# ==============================================================================
const DECAY_1_16_RAW: int = 16
const DECAY_3_32_RAW: int = 24
const DECAY_1_8_RAW: int = 32
const DECAY_3_16_RAW: int = 48
const DECAY_1_4_RAW: int = 64
# ==============================================================================
# 普通滚动衰减表
# ==============================================================================
#
# 每一行：
#
#   [干球, 湿球]
#
# 行索引：
#
#   0 = GRASS
#   1 = TYPE_1
#   2 = MUD
#   3 = SAND
#
# 原十进制表：
#
#   草地   [0.09375, 0.1875]
#   类型1  [0.0625,  0.09375]
#   泥地   [0.09375, 0.125]
#   沙地   [0.09375, 0.1875]
#
# 现在全部直接保存成 raw 参数。
# ==============================================================================
const ROLLING_DECAY_TABLE: Array = [
	[24, 48], # 草地
	[16, 24], # 类型1
	[24, 32], # 泥地
	[24, 48], # 沙地
]
# ==============================================================================
# 触地瞬间衰减表
# ==============================================================================
#
# 和滚动表大部分相同。
#
# 当前确认的区别：
#
#   沙地 LANDING：
#       [48, 48]
#
# 而普通滚动是：
#
#       [24, 48]
# ==============================================================================
const LANDING_DECAY_TABLE: Array = [
	[24, 48], # 草地
	[16, 24], # 类型1
	[24, 32], # 泥地
	[48, 48], # 沙地
]
# ==============================================================================
# 信号
# ==============================================================================
## 每次足球触地并完成水平衰减后发送。
##
## 可以用于调试触地前后的 XY 速度变化。
signal horizontal_landed(
	velocity_before: Vector2,
	velocity_after: Vector2
)
## 足球水平速度完全变成 0 时发送。
signal horizontal_stopped
# ==============================================================================
# 地面参数
# ==============================================================================
@export_group("FC 地面参数")
## 足球当前接触的地面。
##
## 决定 LANDING / ROLLING 使用哪一行衰减参数。
@export var ground_type: GroundType = GroundType.GRASS
## false = 干球
## true  = 湿球
##
## 湿球通常会使用更大的水平速度损耗。
@export var wet_ball: bool = false
# ==============================================================================
# 权威物理状态
# ==============================================================================
## 足球 XY 水平位置。
##
## 单位：1/256 像素。
var horizontal_position_raw: Vector2i = Vector2i.ZERO
## 足球 XY 水平速度。
##
## 表示：
##
##   每个 Logic Tick 应移动多少 raw。
##
## 例如：
##
##   Vector2i(2048, 0)
##
## 等价于：
##
##   Vector2(8.0, 0.0)
var horizontal_velocity_raw: Vector2i = Vector2i.ZERO
## 是否正在执行普通地面滚动逻辑。
##
## true：
##   每个 Logic Tick 调用 process_rolling_velocity()
##
## false：
##   不自动执行滚动衰减。
##
## 注意：
## 这不是“球是不是在空中”的权威状态。
## Z 状态仍然应该由 BallZMovement 管理。
var is_rolling: bool = false
# ==============================================================================
# 当前 Logic Tick 的运动状态
# ==============================================================================
## 当前已经执行到这一 Logic Tick 的第几个 Physics Frame。
##
## 范围：
##
##   0 → 还没开始
##   1 → 第1帧
##   2 → 第2帧
##   3 → 已完成
var tick_motion_frame: int = 0
## 当前 Logic Tick 锁定的总位移。
##
## 每个 Logic Tick 开始时：
##
##   tick_displacement_raw = horizontal_velocity_raw
##
## 后面三个 Physics Frame 都使用这个值。
##
## 即使期间 horizontal_velocity_raw 改变，
## 当前 Tick 的总位移也不会跟着改变。
var tick_displacement_raw: Vector2i = Vector2i.ZERO
# ==============================================================================
# 对外位置 / 速度接口
# ==============================================================================
## 设置足球水平位置。
##
## 外部使用正常 Vector2，组件内部自动转换成 1/256 raw。
func set_horizontal_position(value: Vector2) -> void:
	horizontal_position_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
## 获取足球水平位置。
##
## 将内部 raw 转回正常 Vector2。
func get_horizontal_position() -> Vector2:
	return Vector2(
		_from_raw(horizontal_position_raw.x),
		_from_raw(horizontal_position_raw.y)
	)
## 设置足球水平速度。
func set_horizontal_velocity(value: Vector2) -> void:
	horizontal_velocity_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
## 获取足球水平速度。
func get_horizontal_velocity() -> Vector2:
	return Vector2(
		_from_raw(horizontal_velocity_raw.x),
		_from_raw(horizontal_velocity_raw.y)
	)
# ==============================================================================
# 空中水平运动
# ==============================================================================
## 处理足球空中阶段的水平速度。
##
## steering_y：
##
##   -1 = 上
##    0 = 无输入
##   +1 = 下
##
## steering_enabled：
##
##   只有允许动作 $05 空中操控时才传 true。
##
##
## 例如：
##
## 普通飞行：
##
##   process_air_velocity()
##
## 动作 $05 按住上：
##
##   process_air_velocity(-1, true)
##
## 动作 $05 按住下：
##
##   process_air_velocity(1, true)
##
##
## 注意：
##
## 本函数只修改速度。
## 不直接修改 horizontal_position_raw。
func process_air_velocity(
	steering_y: int = 0,
	steering_enabled: bool = false
) -> void:
	if steering_enabled and steering_y != 0:
		_apply_action_05_steering_raw(steering_y)

	# 进入空中处理后，不再执行普通地面滚动衰减。
	is_rolling = false
## 单独施加动作 $05 的上下操控。
##
## 方便状态机直接调用。
##
## direction_y：
##
##   -1 = 上
##   +1 = 下
func apply_action_05_steering(direction_y: int) -> void:
	if direction_y == 0:
		return
	_apply_action_05_steering_raw(direction_y)
## 动作 $05 实际修改 raw 速度的内部实现。
func _apply_action_05_steering_raw(direction_y: int) -> void:
	horizontal_velocity_raw.y += (
		signi(direction_y)
		* STEERING_STEP_RAW
	)
# ==============================================================================
# 触地
# ==============================================================================
## 足球每一次从空中碰到地面时调用。
##
## 推荐连接：
##
##   BallZMovement.landed
##
##
## 注意：
##
## 这里是“每次触地”，不是：
##
##   BallZMovement.finished
##
## 所以足球：
##
##   第一次落地 → 调一次
##   反弹后再落地 → 再调一次
##   最后一次落地 → 再调一次
##
##
## 本函数：
##
##   ✅ 修改水平速度
##   ❌ 不更新水平坐标
func apply_landing_decay() -> void:
	var velocity_before_raw := horizontal_velocity_raw
	var coefficient_raw := _get_decay_coefficient_raw(
		DecayProfile.LANDING
	)
	horizontal_velocity_raw = _decay_vector_once_raw(
		horizontal_velocity_raw,
		coefficient_raw
	)
	horizontal_landed.emit(
		_vector_raw_to_float(velocity_before_raw),
		get_horizontal_velocity()
	)
# ==============================================================================
# 地面滚动
# ==============================================================================
## 正式进入普通地面滚动阶段。
##
## 一般可以在 BallZMovement.finished 时调用。
func roll() -> void:
	is_rolling = true
## 计算一个 Logic Tick 的滚动速度衰减。
##
## 只修改 horizontal_velocity_raw。
## 不修改 horizontal_position_raw。
##
##
## 原版普通滚动存在一个特殊规则：
##
## ┌───────────────────────────────────────┐
## │ X 和 Y 两个速度分量都进入低速区时， │
## │ 本 Logic Tick 会额外执行一次衰减。    │
## └───────────────────────────────────────┘
##
##
## 因此：
##
## 普通速度：
##
##   衰减一次
##
## X、Y 同时低速：
##
##   衰减一次
##   +
##   正常衰减一次
##   =
##   总共衰减两次
##
##
## 但如果：
##
##   X = 高速
##   Y = 低速
##
## 则不会触发额外调用。
##
## Y 仍然只衰减一次。
func process_rolling_velocity() -> void:
	var coefficient_raw := _get_decay_coefficient_raw(
		DecayProfile.ROLLING
	)
	# --------------------------------------------------------------------------
	# 判断是否触发原版特殊“双衰减”
	# --------------------------------------------------------------------------
	#
	# 两个分量必须同时满足：
	#
	#   -256 <= velocity_raw < 256
	#
	# 才额外执行一次。
	var extra_low_speed_call := (
		_is_low_speed_component(horizontal_velocity_raw.x)
		and
		_is_low_speed_component(horizontal_velocity_raw.y)
	)
	if extra_low_speed_call:
		horizontal_velocity_raw = _decay_vector_once_raw(
			horizontal_velocity_raw,
			coefficient_raw
		)
	# --------------------------------------------------------------------------
	# 普通衰减
	# --------------------------------------------------------------------------
	#
	# 无论是不是低速，
	# 每个滚动 Logic Tick 至少都会执行一次。
	horizontal_velocity_raw = _decay_vector_once_raw(
		horizontal_velocity_raw,
		coefficient_raw
	)
# ==============================================================================
# Logic Tick
# ==============================================================================
## 开始一个新的足球 Logic Tick。
##
## 调用顺序：
##
##   1. 如果正在滚动，先计算新的滚动速度
##   2. 将当前速度锁定成本 Tick 总位移
##   3. 后续三个 Physics Frame 分批完成这个位移
##
##
## 空中时：
##
## process_air_velocity(...)
## step_logic_tick()
##
##
## 滚动时：
##
## roll()
##
## 之后每 Tick：
##
## step_logic_tick()
##
## 本函数内部会自动调用 process_rolling_velocity()。
func step_logic_tick() -> void:
	tick_motion_frame = 0
	# --------------------------------------------------------------------------
	# 地面滚动阶段
	# --------------------------------------------------------------------------
	if is_rolling:
		process_rolling_velocity()
	# --------------------------------------------------------------------------
	# 锁定当前 Tick 位移
	# --------------------------------------------------------------------------
	#
	# FC 一整个 Tick 的水平位移就是当前水平速度。
	tick_displacement_raw = horizontal_velocity_raw
	# --------------------------------------------------------------------------
	# 检查滚动是否彻底停止
	# --------------------------------------------------------------------------
	if is_rolling and horizontal_velocity_raw == Vector2i.ZERO:
		is_rolling = false
		horizontal_stopped.emit()
# ==============================================================================
# Physics Frame 平滑移动
# ==============================================================================
## 将一个 Logic Tick 的总位移分成 3 个 Physics Frame。
##
## 例如：
##
##   tick_displacement_raw.x = 608
##
## 三帧可能得到：
##
##   Frame 1：+203
##   Frame 2：+202
##   Frame 3：+203
##
## 总和：
##
##   608 raw
##
## 因此最终 Logic Tick 坐标与 FC 原结果完全一致。
func _physics_process(_delta: float) -> void:
	if tick_motion_frame >= PHYSICS_FRAMES_PER_LOGIC_TICK:
		return
	tick_motion_frame += 1
	horizontal_position_raw += Vector2i(
		_get_motion_frame_displacement(
			tick_displacement_raw.x,
			tick_motion_frame
		),
		_get_motion_frame_displacement(
			tick_displacement_raw.y,
			tick_motion_frame
		)
	)
## 计算“当前这一帧单独应该移动多少 raw”。
##
## 原理：
##
## 当前帧结束时累计应该移动多少
##
## 减去
##
## 上一帧结束时累计已经移动多少
##
## 等于
##
## 当前这一帧单独移动多少。
##
##
## 例如总位移 608：
##
## Frame 1：
##
##   round(608 × 1/3) - round(608 × 0/3)
##   = 203
##
## Frame 2：
##
##   round(608 × 2/3) - round(608 × 1/3)
##   = 202
##
## Frame 3：
##
##   round(608 × 3/3) - round(608 × 2/3)
##   = 203
##
## 最终：
##
##   203 + 202 + 203 = 608
func _get_motion_frame_displacement(
	total_displacement_raw: int,
	frame: int
) -> int:
	var current_progress := (
		float(frame)
		/
		float(PHYSICS_FRAMES_PER_LOGIC_TICK)
	)
	var previous_progress := (
		float(frame - 1)
		/
		float(PHYSICS_FRAMES_PER_LOGIC_TICK)
	)
	var total_moved_now_raw := roundi(
		total_displacement_raw
		* current_progress
	)
	var total_moved_before_raw := roundi(
		total_displacement_raw
		* previous_progress
	)
	return (
		total_moved_now_raw
		-
		total_moved_before_raw
	)
# ==============================================================================
# 强制停止
# ==============================================================================
## 立即清除水平速度。
##
## 用于：
##
##   - 足球出界
##   - 进球
##   - 守门员完全接住
##   - 强制重置
##
## 不等待自然滚动减速。
func stop_immediately() -> void:
	var was_moving := (
		horizontal_velocity_raw != Vector2i.ZERO
		or is_rolling
	)
	horizontal_velocity_raw = Vector2i.ZERO
	tick_displacement_raw = Vector2i.ZERO
	is_rolling = false
	if was_moving:
		horizontal_stopped.emit()
# ==============================================================================
# 水平衰减
# ==============================================================================
## 对 X、Y 两个速度分量分别执行一次衰减。
##
## 输入和输出全部是 raw。
func _decay_vector_once_raw(
	value_raw: Vector2i,
	coefficient_raw: int
) -> Vector2i:
	return Vector2i(
		_decay_component_once_raw(
			value_raw.x,
			coefficient_raw
		),
		_decay_component_once_raw(
			value_raw.y,
			coefficient_raw
		)
	)
## 对单个速度分量执行一次原版水平衰减。
##
## 分成：
##
##   低速分支
##   高速分支
##
##
## --------------------------------------------------------------------------
## 低速
## --------------------------------------------------------------------------
##
## 原版通过速度高字节判断。
##
## 对应 raw 范围：
##
##   -256 <= value_raw < 256
##
## 即：
##
##   -1.0 <= V <= 0.99609375
##
## 低速情况下不读取 coefficient。
##
## 每次固定向 0 靠近：
##
##   16 raw = 0.0625
##
##
## --------------------------------------------------------------------------
## 高速
## --------------------------------------------------------------------------
##
## 根据 coefficient_raw 使用不同的移位组合计算本次损耗。
func _decay_component_once_raw(
	value_raw: int,
	coefficient_raw: int
) -> int:
	if _is_low_speed_component(value_raw):
		return move_toward(
			value_raw,
			0,
			LOW_SPEED_DECAY_RAW
		)
	var signed_loss_raw := _calculate_signed_loss_raw(
		value_raw,
		coefficient_raw
	)
	return value_raw - signed_loss_raw
# ==============================================================================
# 高速损耗
# ==============================================================================
## 根据原版衰减参数计算“带符号的速度损耗”。
##
## 这里不是简单：
##
##   loss = velocity * coefficient
##
## 而是保留 FC 原版的移位计算顺序。
##
##
## 例如：
##
## coefficient_raw = 24
##
## 表示：
##
##   0.09375
##   =
##   1/16 + 1/32
##
## 所以：
##
##   loss =
##       (velocity >> 4)
##       +
##       (velocity >> 5)
##
##
## 对负数使用算术右移，
## 可以保留原版正负速度的取整非对称性。
func _calculate_signed_loss_raw(
	value_raw: int,
	coefficient_raw: int
) -> int:
	match coefficient_raw:
		# 0.0625 = 1/16
		DECAY_1_16_RAW:
			return value_raw >> 4
		# 0.09375 = 1/16 + 1/32
		DECAY_3_32_RAW:
			return (
				(value_raw >> 4)
				+
				(value_raw >> 5)
			)
		# 0.125 = 1/8
		DECAY_1_8_RAW:
			return value_raw >> 3
		# 0.1875 = 1/8 + 1/16
		DECAY_3_16_RAW:
			return (
				(value_raw >> 3)
				+
				(value_raw >> 4)
			)
		# 0.25 = 1/4
		DECAY_1_4_RAW:
			return value_raw >> 2
		_:
			push_error(
				"BallHorizontalComponent: "
				+ "未支持的水平衰减参数：%d raw"
				% coefficient_raw
			)
			return 0
# ==============================================================================
# 低速判断
# ==============================================================================
## 判断单个水平速度分量是否进入 FC 低速区。
##
## 原版范围：
##
##   -1.0 <= V < 1.0
##
## raw：
##
##   -256 <= value_raw < 256
##
##
## 注意这里存在原版特有的不对称：
##
##   -256 raw = -1.0
##       → 属于低速
##
##   +256 raw = +1.0
##       → 不属于低速
##
## 正方向最大低速值实际上是：
##
##   255 / 256
##   =
##   0.99609375
func _is_low_speed_component(value_raw: int) -> bool:
	return (
		value_raw >= -RAW_ONE
		and
		value_raw < RAW_ONE
	)
# ==============================================================================
# 取得衰减参数
# ==============================================================================
## 根据：
##
##   1. 当前地面
##   2. 干球 / 湿球
##   3. LANDING / ROLLING
##
## 取得对应的 raw 衰减参数。
##
##
## wet_index：
##
##   0 = 干球
##   1 = 湿球
##
##
## ground_index：
##
##   0 = GRASS
##   1 = TYPE_1
##   2 = MUD
##   3 = SAND
func _get_decay_coefficient_raw(
	profile: DecayProfile
) -> int:
	var wet_index := 1 if wet_ball else 0
	var ground_index := int(ground_type) & 3
	if profile == DecayProfile.LANDING:
		return LANDING_DECAY_TABLE[
			ground_index
		][wet_index]
	return ROLLING_DECAY_TABLE[
		ground_index
	][wet_index]
# ==============================================================================
# raw / float 转换
# ==============================================================================
## float → 1/256 raw。
##
## 例如：
##
##   8.0 → 2048
##   0.5 → 128
func _to_raw(value: float) -> int:
	return roundi(value * RAW_ONE)
## 1/256 raw → float。
##
## 例如：
##
##   2048 → 8.0
##   128  → 0.5
func _from_raw(value_raw: int) -> float:
	return float(value_raw) / RAW_ONE
## Vector2i raw → 普通 Vector2。
##
## 主要用于信号和调试输出。
func _vector_raw_to_float(value_raw: Vector2i) -> Vector2:
	return Vector2(
		_from_raw(value_raw.x),
		_from_raw(value_raw.y)
	)
