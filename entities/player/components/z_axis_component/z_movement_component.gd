extends Node
class_name ZMovementBase
const RAW_ONE: int = 256
const GRAVITY: float = 0.5
const PHYSICS_FRAMES_PER_LOGIC_TICK: int = 3
signal launched()
signal landed()
var z_height_raw: int = 0
var z_velocity_raw: int = 0
var is_in_air: bool = false
## 当前 Logic Tick 已经走到第几个 Physics Frame。
var tick_motion_frame: int = 0
## 当前 Logic Tick 总共需要完成的 Z 位移。
var tick_displacement_raw: int = 0
# ==============================================================================
# 外部接口
# ==============================================================================
func set_z_height(value: float) -> void:
	z_height_raw = _to_raw(value)
func get_z_height() -> float:
	return _from_raw(z_height_raw)
func set_z_velocity(value: float) -> void:
	z_velocity_raw = _to_raw(value)
func get_z_velocity() -> float:
	return _from_raw(z_velocity_raw)
func apply_vertical_velocity(initial_velocity: float) -> void:
	z_velocity_raw = _to_raw(initial_velocity)
	is_in_air = true
	launched.emit()
# ==============================================================================
# Logic Tick
# ==============================================================================
func process_z_step() -> void:
	if not is_in_air:
		return
	# 当前 VZ 就是这一整个 Tick 的 Z 位移。
	tick_displacement_raw = z_velocity_raw
	# 新的一段三帧运动开始。
	tick_motion_frame = 0
	# FC：
	# Z += VZ
	# VZ -= 0.5
	#
	# Z += VZ 现在由下面 3 个 Physics Frame 完成。
	z_velocity_raw -= _to_raw(GRAVITY)
# ==============================================================================
# Physics Frame
# ==============================================================================

func _physics_process(_delta: float) -> void:
	if not is_in_air:
		return

	if tick_motion_frame >= PHYSICS_FRAMES_PER_LOGIC_TICK:
		return

	tick_motion_frame += 1

	z_height_raw += _get_motion_frame_displacement(
		tick_displacement_raw,
		tick_motion_frame
	)

	# 只有这个 Logic Tick 的全部位移完成后，
	# 才进行一次 FC 落地判断。
	if tick_motion_frame == PHYSICS_FRAMES_PER_LOGIC_TICK:
		if _check_landing():
			_process_landing()


# ==============================================================================
# 子类规则
# ==============================================================================

func _check_landing() -> bool:
	return false
func should_show_shadow() -> bool:
	return is_in_air

func _process_landing() -> void:
	pass


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

	var current_offset_raw: int = roundi(
		total_displacement_raw * current_progress
	)

	var previous_offset_raw: int = roundi(
		total_displacement_raw * previous_progress
	)

	return current_offset_raw - previous_offset_raw


# ==============================================================================
# Raw
# ==============================================================================

func _to_raw(value: float) -> int:
	return roundi(value * RAW_ONE)


func _from_raw(value: int) -> float:
	return float(value) / RAW_ONE
