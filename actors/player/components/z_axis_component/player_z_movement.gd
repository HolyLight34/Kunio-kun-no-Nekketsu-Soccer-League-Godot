extends ZMovementBase
class_name PlayerZMovement


# ==============================================================================
# 调试
# ==============================================================================

@export_group("Debug")

@export var debug_observation: bool = false
@export var debug_label: String = "player_z"
@export var debug_print_every_step: bool = false

var _debug_step_count: int = 0


# ==============================================================================
# 公共接口
# ==============================================================================

## 角色起跳。
##
## FC 普通跳跃：
## jump(4.0)

# ==============================================================================
# 角色落地规则
# ==============================================================================

func _check_landing() -> bool:
	return (
		z_height_raw <= 0
		and z_velocity_raw < 0
	)


func _process_landing() -> void:
	z_height_raw = 0
	z_velocity_raw = 0
	is_in_air = false
	landed.emit()


# ==============================================================================
# 调试
# ==============================================================================

func _debug_print_step(
	state_name: String,
	z_before_raw: int,
	vz_before_raw: int
) -> void:
	if not debug_observation:
		return

	if (
		not debug_print_every_step
		and state_name == "AIR"
	):
		return

	print(
		"[%s] step=%d %s | "
		+ "Z %.6f -> %.6f raw=%d | "
		+ "VZ %.6f -> %.6f raw=%d"
		% [
			debug_label,
			_debug_step_count,
			state_name,

			_from_raw(z_before_raw),
			_from_raw(z_height_raw),
			z_height_raw,

			_from_raw(vz_before_raw),
			_from_raw(z_velocity_raw),
			z_velocity_raw
		]
	)
