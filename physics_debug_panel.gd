
extends CanvasLayer
class_name PhysicsDebugPanel


@export_group("显示设置")

@export var panel_position: Vector2 = Vector2(12, 12)
@export var panel_width: float = 460.0
@export var font_size: int = 16


@onready var _panel: PanelContainer = $Panel
@onready var _stats_label: RichTextLabel = \
	$Panel/MarginContainer/StatsLabel


# ==============================================================================
# 接收的数据
# ==============================================================================

## 角色的 XYZ 坐标。
var player_position: Vector3 = Vector3.ZERO

## 角色的 XYZ 速度。
var player_velocity: Vector3 = Vector3.ZERO

## 足球的 XYZ 坐标。
var ball_position: Vector3 = Vector3.ZERO

## 足球的 XYZ 速度。
var ball_velocity: Vector3 = Vector3.ZERO


# ==============================================================================
# 生命周期
# ==============================================================================

func _ready() -> void:
	layer = 10

	_panel.position = panel_position
	_panel.custom_minimum_size.x = panel_width

	_stats_label.bbcode_enabled = true
	_stats_label.scroll_active = false

	_stats_label.add_theme_font_size_override(
		"normal_font_size",
		font_size
	)

	_refresh_display()


# ==============================================================================
# 公共接口
# ==============================================================================

## 设置角色的六轴数据。
##
## position:  (X, Y, Z)
## velocity:  (VX, VY, VZ)
func set_player_data(
	position: Vector3,
	velocity: Vector3
) -> void:
	player_position = position
	player_velocity = velocity
	_refresh_display()


## 设置足球的六轴数据。
##
## position:  (X, Y, Z)
## velocity:  (VX, VY, VZ)
func set_ball_data(
	position: Vector3,
	velocity: Vector3
) -> void:
	ball_position = position
	ball_velocity = velocity
	_refresh_display()


## 一次性设置角色和足球的数据。
func set_physics_data(
	new_player_position: Vector3,
	new_player_velocity: Vector3,
	new_ball_position: Vector3,
	new_ball_velocity: Vector3
) -> void:
	player_position = new_player_position
	player_velocity = new_player_velocity

	ball_position = new_ball_position
	ball_velocity = new_ball_velocity

	_refresh_display()


## 清空所有数据。
func clear_data() -> void:
	player_position = Vector3.ZERO
	player_velocity = Vector3.ZERO
	ball_position = Vector3.ZERO
	ball_velocity = Vector3.ZERO

	_refresh_display()


# ==============================================================================
# 显示
# ==============================================================================



func _refresh_display() -> void:
	if not is_instance_valid(_stats_label):
		return

	_stats_label.text = (
		"[color=lime]--- [ 1P ] ---[/color]"
		+ "                         "
		+ "[color=lime]--- [ BALL ] ---[/color]\n"
		+ _format_row(
			"X", player_position.x, "VX", player_velocity.x,
			ball_position.x, ball_velocity.x
		) + "\n"
		+ _format_row(
			"Y", player_position.y, "VY", player_velocity.y,
			ball_position.y, ball_velocity.y
		) + "\n"
		+ _format_row(
			"Z", player_position.z, "VZ", player_velocity.z,
			ball_position.z, ball_velocity.z
		)
	)


func _format_row(
	position_name: String,
	player_position_value: float,
	velocity_name: String,
	player_velocity_value: float,
	ball_position_value: float,
	ball_velocity_value: float
) -> String:
	var player_text := "%s %8.4f %s %+8.4f" % [
		position_name,
		player_position_value,
		velocity_name,
		player_velocity_value
	]

	var ball_text := "%s %8.4f %s %+8.4f" % [
		position_name,
		ball_position_value,
		velocity_name,
		ball_velocity_value
	]

	return player_text + "     " + ball_text




## 设置面板显示状态。
func set_debug_visible(value: bool) -> void:
	visible = value
