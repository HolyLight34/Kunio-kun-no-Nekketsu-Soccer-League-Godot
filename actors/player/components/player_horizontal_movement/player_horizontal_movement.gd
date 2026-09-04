extends Node
class_name PlayerHorizontalMovement
# ==============================================================================
# 类型
# ==============================================================================
enum GroundType {
	GROUND_0 = 0,
	GROUND_1 = 1,
	GROUND_2 = 2,
	GROUND_3 = 3,
}
# ==============================================================================
# 常量
# ==============================================================================
const RAW_ONE: int = 256
const PHYSICS_FRAMES_PER_LOGIC_TICK: int = 3
## FC 基础方向速度。
## 8.0 * 256 = 2048 raw
const BASE_SPEED: float = 8.0
## 空中方向微调量。
const AIR_STEERING_STEP: float = 0.046875
const MAX_AIR_VX: float = 6.0
const MAX_AIR_VY: float = 4.0
## FC 原版减速表。
##
## raw 单位：
## 256 = 1.0
const DECELERATION_RAW: Array = [
	# 普通
	[80, 16, 96, 96],
	# Brake
	[160, 64, 192, 192],
	# Run
	[256, 64, 256, 256],
	# Sprint
	[256, 256, 768, 768],
	# Trap
	[192, 128, 768, 768],
	# 其他
	[128, 32, 192, 192],
	# 其他
	[256, 16, 256, 256],
]
# ==============================================================================
# 信号
# ==============================================================================
signal right_boundary_touched(
	position: Vector2,
	velocity: Vector2
)
signal stopped
# ==============================================================================
# 导出
# ==============================================================================
@export_group("角色数据")
@export var ground_type: GroundType = GroundType.GROUND_0
@export var force_ground_zero: bool = false
@export var wet_ball_global_state: bool = false
@export_group("边界")
@export var enable_right_boundary: bool = false
@export var right_boundary_integer: int = 865
# ==============================================================================
# 权威物理数据
# ==============================================================================
## XY 权威位置，1 / 256 子像素。
var position_raw: Vector2i = Vector2i.ZERO
## XY 权威速度，1 / 256 子像素。
var velocity_raw: Vector2i = Vector2i.ZERO
# ==============================================================================
# 当前 Logic Tick 运动数据
# ==============================================================================
## 当前 Logic Tick 已经执行到第几个 Physics Frame。
var tick_motion_frame: int = 0
## 当前 Logic Tick 总共需要完成的 XY 位移。
##
## 在 Logic Tick 开始时锁定，
## 后续速度发生变化不会影响当前 Tick 已经确定的位移。
var tick_displacement_raw: Vector2i = Vector2i.ZERO
# ==============================================================================
# 外部访问接口
# ==============================================================================
func set_horizontal_position(value: Vector2) -> void:
	position_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
func get_horizontal_position() -> Vector2:
	return Vector2(
		_from_raw(position_raw.x),
		_from_raw(position_raw.y)
	)
func set_horizontal_velocity(value: Vector2) -> void:
	velocity_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
func get_horizontal_velocity() -> Vector2:
	return Vector2(
		_from_raw(velocity_raw.x),
		_from_raw(velocity_raw.y)
	)
# ==============================================================================
# 移动控制
# ==============================================================================
## 根据速度和方向生成 FC 风格速度。
##
## speed:
## 例如 2.375
##
## direction:
## 例如 Vector2.RIGHT
func set_move_velocity(
	speed: float,
	direction: Vector2
) -> void:
	if direction.is_zero_approx():
		velocity_raw = Vector2i.ZERO
		return
	var base_velocity_raw := _get_base_velocity_raw(
		direction.normalized()
	)
	var factor := _to_fc_factor(speed)
	velocity_raw = _velocity_from_factor(
		factor,
		base_velocity_raw
	)
## FC 特定规则：
## Y 速度算术右移一位。
func halve_y_velocity() -> void:
	velocity_raw.y >>= 1
## 空中方向微调。
func apply_air_steering(direction: Vector2) -> void:
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
## 限制空中速度。
func clamp_velocity() -> void:
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
## 强制立即停止。
func stop_immediately() -> void:
	velocity_raw = Vector2i.ZERO
# ==============================================================================
# Logic Tick
# ==============================================================================
## 每个 FC Logic Tick 调用一次。
##
## 本函数不读取输入。
## 输入和状态规则由状态机决定。
##
## 这里负责：
##
## 1. 修正当前速度
## 2. 锁定本 Tick 位移
## 3. 根据 CLASSIC / SMOOTH 决定如何执行位移
func step_logic_tick() -> void:
	clamp_velocity()
	# 当前速度就是整个 Logic Tick 需要完成的位移。
	tick_displacement_raw = velocity_raw
	if GameSettings.is_classic_motion():
		_process_classic_motion()
	else:
		_prepare_smooth_motion()
# ==============================================================================
# Classic
# ==============================================================================
func _process_classic_motion() -> void:
	# 一个 Logic Tick 一次完成全部位移。
	position_raw += tick_displacement_raw
	# 标记当前 Tick 已经全部执行完成。
	tick_motion_frame = PHYSICS_FRAMES_PER_LOGIC_TICK
	# FC 规则层的边界处理放在完整 Tick 位移之后。
	_apply_confirmed_right_boundary()
# ==============================================================================
# Smooth
# ==============================================================================
func _prepare_smooth_motion() -> void:
	# 新的一段三帧运动开始。
	tick_motion_frame = 0
# ==============================================================================
# Physics Frame
# ==============================================================================
func _physics_process(_delta: float) -> void:
	# Classic 已经在 Logic Tick 中完成了整个位置积分。
	if GameSettings.is_classic_motion():
		return
	if tick_motion_frame >= PHYSICS_FRAMES_PER_LOGIC_TICK:
		return
	tick_motion_frame += 1
	position_raw += Vector2i(
		_get_motion_frame_displacement(
			tick_displacement_raw.x,
			tick_motion_frame
		),
		_get_motion_frame_displacement(
			tick_displacement_raw.y,
			tick_motion_frame
		)
	)
	# 只有完整 Logic Tick 位移完成后，
	# 才执行一次 FC 规则层处理。
	if tick_motion_frame == PHYSICS_FRAMES_PER_LOGIC_TICK:
		_apply_confirmed_right_boundary()
# ==============================================================================
# 三帧位移分配
# ==============================================================================
func _get_motion_frame_displacement(
	total_displacement_raw: int,
	frame: int
) -> int:
	var current_progress: float = (
		float(frame)
		/ float(PHYSICS_FRAMES_PER_LOGIC_TICK)
	)
	var previous_progress: float = (
		float(frame - 1)
		/ float(PHYSICS_FRAMES_PER_LOGIC_TICK)
	)
	var total_moved_now_raw: int = roundi(
		total_displacement_raw * current_progress
	)
	var total_moved_before_raw: int = roundi(
		total_displacement_raw * previous_progress
	)
	return total_moved_now_raw - total_moved_before_raw
# ==============================================================================
# FC 速度生成
# ==============================================================================
## 将现代速度转换成 FC Factor。
##
## 例如：
##
## 2.375 * 16 = 38 = $26
func _to_fc_factor(speed: float) -> int:
	return clampi(
		roundi(speed * 16.0),
		0,
		255
	)
## 根据现代方向 Vector2 生成 FC 8.8 基础方向速度。
func _get_base_velocity_raw(
	direction_normalized: Vector2
) -> Vector2i:
	var base_velocity := (
		direction_normalized
		* BASE_SPEED
	)
	return Vector2i(
		_to_raw(base_velocity.x),
		_to_raw(base_velocity.y)
	)
## FC 原版 6502 逐位移位加法。
##
## 不直接执行：
##
## base_velocity * factor
##
## 而是模拟原版逐位处理，
## 保留每一次算术右移产生的整数取整行为。
func _velocity_from_factor(
	factor: int,
	base_velocity_raw: Vector2i
) -> Vector2i:
	var result := Vector2i.ZERO
	var work_factor: int = factor & 255
	var work_base_velocity := base_velocity_raw
	for _i in range(8):
		var carry: bool = (
			work_factor & 128
		) != 0
		work_factor = (
			work_factor << 1
		) & 255
		if carry:
			result += work_base_velocity
		work_base_velocity = Vector2i(
			work_base_velocity.x >> 1,
			work_base_velocity.y >> 1
		)
	return result
# ==============================================================================
# 地面摩擦
# ==============================================================================
## FC 特定地面摩擦规则。
##
## 当前规则：
## X 向 0 衰减，
## Y 直接归零。
func decelerate_xy(amount: float) -> void:
	var amount_raw := _to_raw(amount)
	velocity_raw.x = move_toward(
		velocity_raw.x,
		0,
		amount_raw
	)

	velocity_raw.y = move_toward(
		velocity_raw.y,
		0,
		amount_raw
	)
func decelerate_x_and_stop_y(amount: float) -> void:
	var amount_raw := _to_raw(amount)
	velocity_raw.x = move_toward(
		velocity_raw.x,
		0,
		amount_raw
	)
	velocity_raw.y = 0
# ==============================================================================
# 右边界
# ==============================================================================
## 已确认的 FC 右边界规则。
##
## position_raw 保持 1 / 256 精度，
## 边界只判断整数部分。
##
## 超出边界时：
## 修正整数部分，
## 保留低 8 位子像素。
func _apply_confirmed_right_boundary() -> void:
	if not enable_right_boundary:
		return
	var integer_x: int = position_raw.x >> 8
	if integer_x < right_boundary_integer:
		return
	if integer_x > right_boundary_integer:
		position_raw.x = (
			right_boundary_integer * RAW_ONE
			+ (position_raw.x & 255)
		)
	right_boundary_touched.emit(
		get_horizontal_position(),
		get_horizontal_velocity()
	)
# ==============================================================================
# Raw
# ==============================================================================
func _to_raw(value: float) -> int:
	return roundi(value * RAW_ONE)
func _from_raw(value: int) -> float:
	return float(value) / RAW_ONE
