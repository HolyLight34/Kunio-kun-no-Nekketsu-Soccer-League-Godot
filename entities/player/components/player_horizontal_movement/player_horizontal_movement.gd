
extends Node
class_name PlayerHorizontalMovement

enum GroundType
{
	GROUND_0 = 0,
	GROUND_1 = 1,
	GROUND_2 = 2,
	GROUND_3 = 3,
}
const RAW_ONE:int = 256
const DECELERATION_RAW = [

	# 普通
	[80,16,96,96],

	# brake
	[160,64,192,192],

	# run
	[256,64,256,256],

	# sprint
	[256,256,768,768],

	# trap
	[192,128,768,768],

	# 其他
	[128,32,192,192],

	# 其他
	[256,16,256,256],
]
signal right_boundary_touched(
	position:Vector2,
	velocity:Vector2
)
signal stopped
# ==============================================================================
# 导出
# ==============================================================================
@export_group("角色数据")
@export var ground_type:GroundType = GroundType.GROUND_0
@export var force_ground_zero:bool=false
@export var wet_ball_global_state:bool=false
@export_group("计算")
@export var prefer_float_math:bool=true
@export_group("边界")
@export var enable_right_boundary:bool=false
@export var right_boundary_integer:int=865
# ==============================================================================
# 运行时数据
# ==============================================================================
# 位置 raw
var position_raw:Vector2i = Vector2i.ZERO
# 速度 raw
var velocity_raw:Vector2i = Vector2i.ZERO
var facing_left:bool=false
# ==============================================================================
# 生命周期
# ==============================================================================
# ==============================================================================
# 外部访问接口
# ==============================================================================
func set_horizontal_position(value:Vector2)->void:
	position_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
	#_sync_target()
func get_horizontal_position()->Vector2:
	print(Vector2(
		_from_raw(position_raw.x),
		_from_raw(position_raw.y)
	))
	return Vector2(
		_from_raw(position_raw.x),
		_from_raw(position_raw.y)
	)
func set_horizontal_velocity(value:Vector2)->void:
	velocity_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
func get_horizontal_velocity()->Vector2:
	return Vector2(
		_from_raw(velocity_raw.x),
		_from_raw(velocity_raw.y)
	)
# ==============================================================================
# 状态控制接口
# ==============================================================================
## 普通移动
##
## 对应 FC 普通走动速度
##
## 开启普通走动 (Action $20)
## 外部直接传入现代化的方向向量 (如手柄/键盘的 Vector2)
func _to_fc_factor(speed: float) -> int:
	return clampi(roundi(speed * 16.0), 0, 255)
func set_move_velocity(
	speed: float,
	direction: Vector2
) -> void:
	var direction_velocity_raw := (
		_get_base_velocity_raw(direction.normalized())
	)
	var factor := _to_fc_factor(speed)
	velocity_raw = _velocity_from_factor(
		factor,
		direction_velocity_raw
	)

## 反向刹车
## FC $8C3C:
## Y轴速度算术右移一位
## 保留NES整数取整规则
func halve_y_velocity() -> void:
	velocity_raw.y >>= 1
const AIR_STEERING_STEP: float = 0.046875
func apply_air_steering(
	direction: Vector2
) -> void:
	if direction.is_zero_approx():
		return
	var steering_delta := (
		direction.normalized()
		* AIR_STEERING_STEP
	)
	velocity_raw += Vector2i(
		_to_raw(steering_delta.x),
		_to_raw(steering_delta.y)
	)
const MAX_AIR_VX: float = 6.0
const MAX_AIR_VY: float = 4.0
func clamp_air_velocity() -> void:
	var max_x := _to_raw(MAX_AIR_VX)
	var max_y := _to_raw(MAX_AIR_VY)
	velocity_raw.x = clampi(
		velocity_raw.x,
		-max_x,
		max_x
	)
	velocity_raw.y = clampi(
		velocity_raw.y,
		-max_y,
		max_y
	)
## 强制停止
func stop_immediately()->void:
	velocity_raw = Vector2i.ZERO
# ==============================================================================
# 每个 FC 逻辑 Tick 调用
#
# 注意：
#
# 这里不读取输入。
#
# 输入由状态机处理。
#
# 本函数只：
#
# 1. 速度衰减
# 2. 坐标积分
# 3. 冲刺结束
#
# ==============================================================================
func step_logic_tick()->void:
	clamp_air_velocity()
	position_raw += velocity_raw
	#_sync_target()
const BASE_SPEED: float = 8.0
func _get_base_velocity_raw(
	direction_normalized: Vector2
) -> Vector2i:

	var base_velocity := (
		direction_normalized * BASE_SPEED
	)

	return Vector2i(
		_to_raw(base_velocity.x),
		_to_raw(base_velocity.y)
	)
# 使用 FC 原版 6502 逐位移位加法生成速度。
#
# 不使用浮点乘法，保证：
#
# 1. 每次移位后的取整行为与原版一致
# 2. raw速度结果与Mesen逐帧对比一致
#
# 输出:
# Vector2i(raw速度)
func _velocity_from_factor(
	factor: int,
	base_velocity_raw: Vector2i
)->Vector2i:
	var result := Vector2i.ZERO
	var work_factor:int = factor & 255
	for _i in range(8):
		var carry:bool = (
			work_factor & 128
		) != 0
		work_factor = (
			work_factor << 1
		) & 255
		if carry:
			result += base_velocity_raw
		base_velocity_raw = Vector2i(
			base_velocity_raw.x >> 1,
			base_velocity_raw.y >> 1
		)
	return result
# ==============================================================================
# 获取跑步速度倍率
#
# 对应 FC 中：
#
# 根据：
#
# - 地面
# - 球状态
# - 湿地
# - 角色类型
#
# 修改速度 factor
#
# ==============================================================================
# ==============================================================================
# 获取当前移动速度组
#
# 对应 FC 地面判断逻辑
#
# ==============================================================================

# ==============================================================================
# 原版减速
#
# value:
#
# 当前速度 raw
#
# amount:
#
# 每Tick减少多少raw
#
# ==============================================================================
func apply_ground_friction(
	amount: float
) -> void:
	var amount_raw := _to_raw(amount)
	# FC规则：
	# 地面摩擦只处理X速度
	# Y速度直接归零
	velocity_raw.x = move_toward(
		velocity_raw.x,
		0,
		amount_raw
	)
	velocity_raw.y = 0
# ==============================================================================
# 右边界限制
#
# FC:
#
# 坐标仍然保持raw
#
# 只限制整数部分
#
# 低8位子像素保留
#
# ==============================================================================
func _apply_confirmed_right_boundary()->void:
	if not enable_right_boundary:
		return
	var integer_x:int = (
		position_raw.x >> 8
	)
	if integer_x < right_boundary_integer:
		return
	# 超出边界时修正
	if integer_x > right_boundary_integer:
		position_raw.x = (
			right_boundary_integer * RAW_ONE
			+
			(position_raw.x & 255)
		)
	right_boundary_touched.emit(
		get_horizontal_position(),
		get_horizontal_velocity()
	)
# ==============================================================================
# 方向处理
# ==============================================================================
# ==============================================================================
# 状态bit
#
# FC中的一个byte状态
#
# ==========================================================================
# float <-> FC 8.8
#
# ==============================================================================
func _to_raw(value:float)->int:
	return roundi(
		value * RAW_ONE
	)
func _from_raw(value:int)->float:
	return (
		float(value)
		/
		RAW_ONE
	)
# ==============================================================================
# 显示同步
#
# 物理：
#
# position_raw
#
# ↓
#
# float
#
# ↓
#
# Node2D
#
# ==============================================================================
#func _sync_target()->void:
	#if target_node == null:
		#return
	#var value:Vector2 = get_position()
	#if smooth_subpixel_rendering:
		#target_node.position = value
	#else:
		#target_node.position = value.round()
