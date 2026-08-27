# ==============================================================================
# FC《热血足球》角色水平移动组件（Godot 4）
#
# 默认使用现代浮点乘法生成速度；浮点结果不可用或关闭现代模式时，
# 自动回退到原版 8 轮逐位移位加法。
#
# 本组件不乘 delta。外部状态机每个“角色逻辑步”调用 step_logic_tick() 一次。
# ==============================================================================
extends Node
class_name PlayerHorizontalComponent1


enum PlayerType {
	A = 0,
	B = 1,
	C = 2,
	D = 3,
}

enum GroundType {
	GROUND_0 = 0,
	GROUND_1 = 1,
	GROUND_2 = 2,
	GROUND_3 = 3,
}

enum MoveState {
	IDLE,
	ORDINARY,
	RUN,
	SPRINT,
	BRAKE,
}

enum DirectionCode {
	UP = 0x00,
	UP_RIGHT = 0x20,
	RIGHT = 0x40,
	DOWN_RIGHT = 0x60,
	DOWN = 0x80,
	DOWN_LEFT = 0xA0,
	LEFT = 0xC0,
	UP_LEFT = 0xE0,
}


const RAW_ONE: int = 256

const SPEED_FACTOR_TABLE = [
	[0x40, 0x36, 0x34, 0x32],
	[0x34, 0x33, 0x32, 0x30],
	[0x24, 0x28, 0x2C, 0x30],
	[0x27, 0x2A, 0x2D, 0x30],
	[0x50, 0x50, 0x50, 0x50],
	[0x34, 0x32, 0x30, 0x2E],
	[0x38, 0x36, 0x34, 0x32],
	[0x25, 0x26, 0x27, 0x28],
	[0x70, 0x70, 0x70, 0x70],
]

const SPEED_PENALTY_DRY = [0x08, 0x06, 0x04, 0x02]
const SPEED_PENALTY_WET = [0x10, 0x0C, 0x08, 0x04]

const DIRECTION_BASE_RAW: Array[Vector2i] = [
	Vector2i(0, -2048),
	Vector2i(1448, -1448),
	Vector2i(2048, 0),
	Vector2i(1448, 1448),
	Vector2i(0, 2048),
	Vector2i(-1448, 1448),
	Vector2i(-2048, 0),
	Vector2i(-1448, -1448),
]

const DECELERATION_RAW = [
	[80, 16, 96, 96],
	[160, 64, 192, 192],
	[256, 64, 256, 256],
	[256, 256, 768, 768],
	[192, 128, 768, 768],
	[128, 32, 192, 192],
	[256, 16, 256, 256],
]

const ORDINARY_GROUP: int = 7
const SPRINT_FACTOR: int = 0x50
const CONFIRMED_SPRINT_INTEGRATION_TICKS: int = 7
const STATUS_PAIRED: int = 0x01
const STATUS_RUNNING: int = 0x08
const STATUS_TRAPPING_BALL: int = 0x10


signal stepped(position: Vector2, velocity: Vector2, state: MoveState)
signal state_changed(previous: MoveState, current: MoveState)
signal right_boundary_touched(position: Vector2, velocity: Vector2)
signal stopped


@export_group("目标节点")
@export var target_node: Node2D

@export_group("角色数据")
@export var player_type: PlayerType = PlayerType.B
@export var ground_type: GroundType = GroundType.GROUND_0
@export var force_ground_zero: bool = false
@export var wet_ball_global_state: bool = false

@export_group("计算方式")
## 默认使用浮点乘法。关闭后始终使用原版逐位移位算法。
@export var prefer_modern_float_math: bool = true

@export_group("已确认边界")
@export var enable_confirmed_right_boundary: bool = false
@export var right_boundary_integer: int = 865

@export_group("显示")
@export var smooth_subpixel_rendering: bool = true


## 位置积分仍保留 8.8 raw 格式，以兼容原版边界与子像素行为。
var position_raw := Vector2i.ZERO
var velocity_raw := Vector2i.ZERO
var move_state: MoveState = MoveState.IDLE
var direction_code: int = DirectionCode.RIGHT
var facing_left: bool = false
var status_flags: int = 0
var sprint_ticks_remaining: int = 0


func _ready() -> void:
	if target_node:
		set_position(target_node.position)
	_sync_target()


func set_position(value: Vector2) -> void:
	position_raw = Vector2i(_to_raw(value.x), _to_raw(value.y))
	_sync_target()


func get_position() -> Vector2:
	return Vector2(_from_raw(position_raw.x), _from_raw(position_raw.y))


func set_velocity(value: Vector2) -> void:
	velocity_raw = Vector2i(_to_raw(value.x), _to_raw(value.y))


func get_velocity() -> Vector2:
	return Vector2(_from_raw(velocity_raw.x), _from_raw(velocity_raw.y))


func set_status_flags(value: int) -> void:
	status_flags = value & 0xFF


func set_trapping_ball(enabled: bool) -> void:
	_set_status_bit(STATUS_TRAPPING_BALL, enabled)


func set_tower_pair_enabled(enabled: bool) -> void:
	_set_status_bit(STATUS_PAIRED, enabled)


func start_ordinary(input_direction_code: int) -> void:
	_set_direction(input_direction_code)
	_set_state(MoveState.ORDINARY)
	_set_status_bit(STATUS_RUNNING, false)
	velocity_raw = _velocity_from_factor(
		SPEED_FACTOR_TABLE[ORDINARY_GROUP][player_type], direction_code
	)


func start_run(input_direction_code: int) -> void:
	_set_direction(input_direction_code)
	_set_state(MoveState.RUN)
	_set_status_bit(STATUS_RUNNING, true)
	velocity_raw = _velocity_from_factor(_get_run_factor(), direction_code)


func start_sprint(
	input_direction_code: int,
	integration_ticks: int = CONFIRMED_SPRINT_INTEGRATION_TICKS
) -> void:
	_set_direction(input_direction_code)
	_set_state(MoveState.SPRINT)
	_set_status_bit(STATUS_RUNNING, true)
	sprint_ticks_remaining = maxi(integration_ticks, 1)
	velocity_raw = _velocity_from_factor(SPRINT_FACTOR, direction_code)


func release_direction() -> void:
	if move_state == MoveState.ORDINARY:
		_set_state(MoveState.IDLE)


func start_reverse_brake(new_direction_code: int) -> void:
	_set_direction(new_direction_code)
	_set_state(MoveState.BRAKE)
	_set_status_bit(STATUS_RUNNING, false)


func stop_immediately() -> void:
	velocity_raw = Vector2i.ZERO
	sprint_ticks_remaining = 0
	_set_status_bit(STATUS_RUNNING, false)
	_set_state(MoveState.IDLE)
	stopped.emit()


func step_logic_tick() -> void:
	match move_state:
		MoveState.IDLE:
			velocity_raw = _move_velocity_toward_zero(velocity_raw, 4)
		MoveState.BRAKE:
			velocity_raw = _move_velocity_toward_zero(velocity_raw, 2)
			if velocity_raw == Vector2i.ZERO:
				_set_state(MoveState.IDLE)
				stopped.emit()
		MoveState.SPRINT, MoveState.ORDINARY, MoveState.RUN:
			pass

	position_raw += velocity_raw
	_apply_confirmed_right_boundary()

	if move_state == MoveState.SPRINT:
		sprint_ticks_remaining -= 1
		if sprint_ticks_remaining <= 0:
			_set_state(MoveState.RUN)
			velocity_raw = _velocity_from_factor(_get_run_factor(), direction_code)

	_sync_target()
	stepped.emit(get_position(), get_velocity(), move_state)


func _get_run_group() -> int:
	if (status_flags & 0x11) != 0:
		if (status_flags & STATUS_TRAPPING_BALL) != 0:
			return 5
		return 6
	if force_ground_zero:
		return 0
	return int(ground_type) & 3


func _get_run_factor() -> int:
	var group := _get_run_group()
	var factor: int = SPEED_FACTOR_TABLE[group][player_type]
	if group < 5:
		var penalty := SPEED_PENALTY_WET if wet_ball_global_state else SPEED_PENALTY_DRY
		factor -= penalty[player_type]
	return factor


## 优先使用现代浮点乘法。任何非有限结果都会自动回退到原版算法。
func _velocity_from_factor(factor: int, input_direction_code: int) -> Vector2i:
	if prefer_modern_float_math:
		var index := ((input_direction_code & 0xE0) >> 5) & 7
		var base := DIRECTION_BASE_RAW[index]
		var normalized_factor := factor & 0xFF
		# 原移位循环的等价缩放是 factor / 128，而不是 factor / 256。
		var scale := float(normalized_factor) / 128.0
		var float_result := Vector2(float(base.x) * scale, float(base.y) * scale)
		if float_result.is_finite():
			return Vector2i(roundi(float_result.x), roundi(float_result.y))

	return _velocity_from_factor_legacy(factor, input_direction_code)


## 原版 $99F3-$9A56：8 轮逐位移位加法，作为兼容与自动回退路径。
func _velocity_from_factor_legacy(factor: int, input_direction_code: int) -> Vector2i:
	var index := ((input_direction_code & 0xE0) >> 5) & 7
	var base := DIRECTION_BASE_RAW[index]
	var result := Vector2i.ZERO
	var work_factor := factor & 0xFF

	for _iteration in range(8):
		var carry := (work_factor & 0x80) != 0
		work_factor = (work_factor << 1) & 0xFF
		if carry:
			result += base
		base = Vector2i(base.x >> 1, base.y >> 1)

	return result


func _move_velocity_toward_zero(value: Vector2i, mode: int) -> Vector2i:
	var effective_ground := 0 if force_ground_zero else (int(ground_type) & 3)
	var amount: int = DECELERATION_RAW[mode][effective_ground]
	return Vector2i(
		_move_component_toward_zero(value.x, amount),
		_move_component_toward_zero(value.y, amount)
	)


func _move_component_toward_zero(value: int, amount: int) -> int:
	if value > 0:
		return maxi(value - amount, 0)
	if value < 0:
		return mini(value + amount, 0)
	return 0


func _apply_confirmed_right_boundary() -> void:
	if not enable_confirmed_right_boundary:
		return

	var integer_x := position_raw.x >> 8
	if integer_x < right_boundary_integer:
		return

	if move_state == MoveState.RUN or move_state == MoveState.SPRINT:
		_set_status_bit(STATUS_RUNNING, false)
		_set_state(MoveState.IDLE)

	# 这段必须保留原 raw 算法，才能保留低 8 位子像素。
	if integer_x > right_boundary_integer:
		position_raw.x = right_boundary_integer * RAW_ONE + (position_raw.x & 0xFF)

	right_boundary_touched.emit(get_position(), get_velocity())


func _set_direction(value: int) -> void:
	direction_code = value & 0xE0
	if direction_code in [DirectionCode.LEFT, DirectionCode.UP_LEFT, DirectionCode.DOWN_LEFT]:
		facing_left = true
	elif direction_code in [DirectionCode.RIGHT, DirectionCode.UP_RIGHT, DirectionCode.DOWN_RIGHT]:
		facing_left = false


func _set_status_bit(bit: int, enabled: bool) -> void:
	if enabled:
		status_flags |= bit
	else:
		status_flags &= ~bit


func _set_state(value: MoveState) -> void:
	if move_state == value:
		return
	var previous := move_state
	move_state = value
	state_changed.emit(previous, move_state)


func _to_raw(value: float) -> int:
	return roundi(value * RAW_ONE)


func _from_raw(value: int) -> float:
	return float(value) / RAW_ONE


func _sync_target() -> void:
	if target_node == null:
		return
	var value := get_position()
	target_node.position = value if smooth_subpixel_rendering else value.round()
