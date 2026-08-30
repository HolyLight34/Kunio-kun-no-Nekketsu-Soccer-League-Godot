# ==============================================================================
# FC《热血足球》普通足球水平物理组件
# ==============================================================================
#
# 负责：
#
# 1. 足球 XY 权威位置
# 2. 足球 XY 权威速度
# 3. 动作 $05 空中上下微调
# 4. 每次 LANDING 水平速度衰减
# 5. ROLLING 持续减速
# 6. CLASSIC / SMOOTH 两种 Logic Tick 位移执行方式
#
#
# ------------------------------------------------------------------------------
# 时间模式
# ------------------------------------------------------------------------------
#
# CLASSIC：
#
# Logic Tick
# ↓
# 计算当前速度
# ↓
# 锁定 Tick 位移
# ↓
# 一次完成整个 XY 位移
#
#
# SMOOTH：
#
# Logic Tick
# ↓
# 计算当前速度
# ↓
# 锁定 Tick 位移
# ↓
# Physics Frame 1 / 2 / 3 分批完成
#
#
# 两种模式每个 Logic Tick 最终得到的 raw 坐标必须相同。
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
	## 足球已经完全进入普通地面滚动阶段。
	ROLLING,
	## 足球每一次从空中触碰地面。
	LANDING,
}
# ==============================================================================
# 基础常量
# ==============================================================================
## FC 水平物理使用 1 / 256 精度。
const RAW_ONE: int = 256
## SMOOTH 模式：
## 1 Logic Tick = 3 Physics Frame。
const PHYSICS_FRAMES_PER_LOGIC_TICK: int = 3
# ==============================================================================
# 动作 $05 空中操控
# ==============================================================================
## 0.5 × 256 = 128 raw
const STEERING_STEP_RAW: int = 128
# ==============================================================================
# 低速衰减
# ==============================================================================
## 0.0625 × 256 = 16 raw
const LOW_SPEED_DECAY_RAW: int = 16
# ==============================================================================
# 高速衰减参数
# ==============================================================================
const DECAY_1_16_RAW: int = 16
const DECAY_3_32_RAW: int = 24
const DECAY_1_8_RAW: int = 32
const DECAY_3_16_RAW: int = 48
const DECAY_1_4_RAW: int = 64
# ==============================================================================
# 普通滚动衰减表
# ==============================================================================
## 每行：
##
## [干球, 湿球]
##
## 0 = GRASS
## 1 = TYPE_1
## 2 = MUD
## 3 = SAND
const ROLLING_DECAY_TABLE: Array = [
	[24, 48],
	[16, 24],
	[24, 32],
	[24, 48],
]
# ==============================================================================
# LANDING 衰减表
# ==============================================================================
const LANDING_DECAY_TABLE: Array = [
	[24, 48],
	[16, 24],
	[24, 32],
	[48, 48],
]
# ==============================================================================
# 信号
# ==============================================================================
## 每次触地水平衰减完成后发送。
signal horizontal_landed(
	velocity_before: Vector2,
	velocity_after: Vector2
)
## 水平滚动完全停止。
signal horizontal_stopped
# ==============================================================================
# 地面参数
# ==============================================================================
@export_group("FC 地面参数")
@export var ground_type: GroundType = GroundType.GRASS
## false = 干球
## true  = 湿球
@export var wet_ball: bool = false
# ==============================================================================
# 权威物理状态
# ==============================================================================
## 足球 XY 权威位置。
##
## 单位：
## 1 / 256 像素。
var horizontal_position_raw: Vector2i = Vector2i.ZERO
## 足球 XY 权威速度。
##
## 表示：
## 每个 Logic Tick 应移动多少 raw。
var horizontal_velocity_raw: Vector2i = Vector2i.ZERO
## 是否处于普通地面滚动状态。
##
## 注意：
## 这不是空中状态。
## 空中状态由 BallZMovement 管理。
var is_rolling: bool = false
# ==============================================================================
# 当前 Logic Tick 运动数据
# ==============================================================================
## 当前 Tick 已执行到第几个 Physics Frame。
var tick_motion_frame: int = 0
## 当前 Logic Tick 锁定的总位移。
##
## Tick 开始以后，即使 velocity 再变化，
## 当前 Tick 位移也不会变化。
var tick_displacement_raw: Vector2i = Vector2i.ZERO
# ==============================================================================
# 对外位置 / 速度接口
# ==============================================================================
func set_horizontal_position(value: Vector2) -> void:
	horizontal_position_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
func get_horizontal_position() -> Vector2:
	return Vector2(
		_from_raw(horizontal_position_raw.x),
		_from_raw(horizontal_position_raw.y)
	)
func set_horizontal_velocity(value: Vector2) -> void:
	horizontal_velocity_raw = Vector2i(
		_to_raw(value.x),
		_to_raw(value.y)
	)
func get_horizontal_velocity() -> Vector2:
	return Vector2(
		_from_raw(horizontal_velocity_raw.x),
		_from_raw(horizontal_velocity_raw.y)
	)
# ==============================================================================
# 空中水平速度
# ==============================================================================
## 处理足球空中阶段水平速度。
##
## steering_y:
##
## -1 = 上
##  0 = 无输入
## +1 = 下
##
## steering_enabled:
## 只有动作 $05 允许空中微调时为 true。
##
## 本函数只修改速度。
func process_air_velocity(
	steering_y: int = 0,
	steering_enabled: bool = false
) -> void:
	if steering_enabled and steering_y != 0:
		_apply_action_05_steering_raw(
			steering_y
		)
	is_rolling = false
## 单独执行动作 $05 上下微调。
func apply_action_05_steering(
	direction_y: int
) -> void:
	if direction_y == 0:
		return
	_apply_action_05_steering_raw(
		direction_y
	)
func _apply_action_05_steering_raw(
	direction_y: int
) -> void:
	horizontal_velocity_raw.y += (
		signi(direction_y)
		* STEERING_STEP_RAW
	)
# ==============================================================================
# LANDING
# ==============================================================================
## 足球每一次碰地时调用。
##
## 一般连接：
##
## BallZMovement.landed
##
## 注意：
##
## 第一次落地
## 反弹
## 第二次落地
## 再反弹
##
## 每一次都会调用。
##
## 本函数：
##
## ✅ 修改水平速度
## ❌ 不修改水平位置
func apply_landing_decay() -> void:
	var velocity_before_raw := (
		horizontal_velocity_raw
	)
	var coefficient_raw := (
		_get_decay_coefficient_raw(
			DecayProfile.LANDING
		)
	)
	horizontal_velocity_raw = (
		_decay_vector_once_raw(
			horizontal_velocity_raw,
			coefficient_raw
		)
	)
	horizontal_landed.emit(
		_vector_raw_to_float(
			velocity_before_raw
		),
		get_horizontal_velocity()
	)
# ==============================================================================
# ROLLING
# ==============================================================================
## 正式进入普通滚动状态。
func roll() -> void:
	is_rolling = true
## 执行一个 Logic Tick 的滚动衰减。
##
## 这里只修改速度。
func process_rolling_velocity() -> void:
	var coefficient_raw := (
		_get_decay_coefficient_raw(
			DecayProfile.ROLLING
		)
	)
	# --------------------------------------------------------------------------
	# 原版特殊低速双衰减
	# --------------------------------------------------------------------------
	var extra_low_speed_call := (
		_is_low_speed_component(
			horizontal_velocity_raw.x
		)
		and
		_is_low_speed_component(
			horizontal_velocity_raw.y
		)
	)
	if extra_low_speed_call:
		horizontal_velocity_raw = (
			_decay_vector_once_raw(
				horizontal_velocity_raw,
				coefficient_raw
			)
		)
	# --------------------------------------------------------------------------
	# 普通衰减
	# --------------------------------------------------------------------------
	horizontal_velocity_raw = (
		_decay_vector_once_raw(
			horizontal_velocity_raw,
			coefficient_raw
		)
	)
# ==============================================================================
# Logic Tick
# ==============================================================================
## 开始一个新的足球 Logic Tick。
##
## 顺序：
##
## 1. 如果正在 rolling，先衰减速度
## 2. 锁定当前 Tick 位移
## 3. 判断是否停止
## 4. CLASSIC 一次移动 / SMOOTH 准备三帧移动
func step_logic_tick() -> void:
	# --------------------------------------------------------------------------
	# 先处理本 Tick 速度
	# --------------------------------------------------------------------------
	if is_rolling:
		process_rolling_velocity()
	# --------------------------------------------------------------------------
	# 锁定本 Tick 位移
	# --------------------------------------------------------------------------
	tick_displacement_raw = (
		horizontal_velocity_raw
	)
	# --------------------------------------------------------------------------
	# 滚动彻底停止
	# --------------------------------------------------------------------------
	if (
		is_rolling
		and
		horizontal_velocity_raw == Vector2i.ZERO
	):
		is_rolling = false
		horizontal_stopped.emit()
	# --------------------------------------------------------------------------
	# 决定如何执行位置积分
	# --------------------------------------------------------------------------
	if GameSettings.is_classic_motion():
		_process_classic_motion()
	else:
		_prepare_smooth_motion()
# ==============================================================================
# CLASSIC
# ==============================================================================
## 一个 Logic Tick 一次完成全部水平位移。
func _process_classic_motion() -> void:
	horizontal_position_raw += (
		tick_displacement_raw
	)
	tick_motion_frame = (
		PHYSICS_FRAMES_PER_LOGIC_TICK
	)
# ==============================================================================
# SMOOTH
# ==============================================================================
## 准备开始新的三帧运动。
func _prepare_smooth_motion() -> void:
	tick_motion_frame = 0
# ==============================================================================
# Physics Frame
# ==============================================================================
func _physics_process(_delta: float) -> void:
	# CLASSIC 已经在 Logic Tick 中完成位置积分。
	if GameSettings.is_classic_motion():
		return
	if (
		tick_motion_frame
		>= PHYSICS_FRAMES_PER_LOGIC_TICK
	):
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
# ==============================================================================
# 三帧位移分配
# ==============================================================================
## 计算当前这一 Physics Frame 单独应该移动多少 raw。
##
## 例：
##
## 总位移 = 608
##
## Frame 1 = 203
## Frame 2 = 202
## Frame 3 = 203
##
## 总计 = 608
func _get_motion_frame_displacement(
	total_displacement_raw: int,
	frame: int
) -> int:
	var current_progress := (
		float(frame)
		/ float(PHYSICS_FRAMES_PER_LOGIC_TICK)
	)
	var previous_progress := (
		float(frame - 1)
		/ float(PHYSICS_FRAMES_PER_LOGIC_TICK)
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
func stop_immediately() -> void:
	var was_moving := (
		horizontal_velocity_raw
		!= Vector2i.ZERO
		or
		is_rolling
	)
	horizontal_velocity_raw = (
		Vector2i.ZERO
	)
	tick_displacement_raw = (
		Vector2i.ZERO
	)
	is_rolling = false
	if was_moving:
		horizontal_stopped.emit()
# ==============================================================================
# 水平衰减
# ==============================================================================
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
func _decay_component_once_raw(
	value_raw: int,
	coefficient_raw: int
) -> int:
	# --------------------------------------------------------------------------
	# 低速
	# --------------------------------------------------------------------------
	if _is_low_speed_component(
		value_raw
	):
		return move_toward(
			value_raw,
			0,
			LOW_SPEED_DECAY_RAW
		)
	# --------------------------------------------------------------------------
	# 高速
	# --------------------------------------------------------------------------
	var signed_loss_raw := (
		_calculate_signed_loss_raw(
			value_raw,
			coefficient_raw
		)
	)
	return (
		value_raw
		-
		signed_loss_raw
	)
# ==============================================================================
# 高速损耗
# ==============================================================================
func _calculate_signed_loss_raw(
	value_raw: int,
	coefficient_raw: int
) -> int:
	match coefficient_raw:
		# 1 / 16
		DECAY_1_16_RAW:
			return (
				value_raw >> 4
			)
		# 3 / 32
		DECAY_3_32_RAW:
			return (
				(value_raw >> 4)
				+
				(value_raw >> 5)
			)
		# 1 / 8
		DECAY_1_8_RAW:
			return (
				value_raw >> 3
			)
		# 3 / 16
		DECAY_3_16_RAW:
			return (
				(value_raw >> 3)
				+
				(value_raw >> 4)
			)
		# 1 / 4
		DECAY_1_4_RAW:
			return (
				value_raw >> 2
			)
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
## FC 原版低速范围：
##
## -256 <= value_raw < 256
##
## 即：
##
## -1.0 属于低速
## +1.0 不属于低速
func _is_low_speed_component(
	value_raw: int
) -> bool:
	return (
		value_raw >= -RAW_ONE
		and
		value_raw < RAW_ONE
	)
# ==============================================================================
# 衰减参数
# ==============================================================================
func _get_decay_coefficient_raw(
	profile: DecayProfile
) -> int:
	var wet_index := (
		1 if wet_ball else 0
	)
	var ground_index := (
		int(ground_type) & 3
	)
	if profile == DecayProfile.LANDING:
		return LANDING_DECAY_TABLE[
			ground_index
		][wet_index]
	return ROLLING_DECAY_TABLE[
		ground_index
	][wet_index]
# ==============================================================================
# Raw / Float
# ==============================================================================
func _to_raw(value: float) -> int:
	return roundi(
		value * RAW_ONE
	)
func _from_raw(
	value_raw: int
) -> float:
	return (
		float(value_raw)
		/ RAW_ONE
	)
func _vector_raw_to_float(
	value_raw: Vector2i
) -> Vector2:
	return Vector2(
		_from_raw(value_raw.x),
		_from_raw(value_raw.y)
	)
