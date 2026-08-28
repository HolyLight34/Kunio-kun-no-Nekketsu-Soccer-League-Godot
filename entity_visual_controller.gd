extends Node
class_name EntityVisualController

@export_group("Movement Components")

@export var horizontal_movement: Node
@export var z_movement: ZMovementBase


@export_group("Visual Nodes")

@export var position_target: Node2D
@export var visual_pivot: Node2D
@export var shadow_sprite: Sprite2D


@export_group("Rendering")

@export var smooth_subpixel_rendering: bool = true


func _physics_process(_delta: float) -> void:
	_apply_visual_state(
		_get_horizontal_position(),
		_get_visual_z_height()
	)

func _ready() -> void:
	process_physics_priority = 100
func initialize() -> void:
	_apply_visual_state(
		_get_horizontal_position(),
		_get_visual_z_height()
	)

func _apply_visual_state(
	horizontal_position: Vector2,
	z_height: float
) -> void:
	var display_position := horizontal_position
	var display_z := z_height

	if not smooth_subpixel_rendering:
		display_position = display_position.floor()
		display_z = floorf(display_z)

	if position_target:
		position_target.position = display_position

	if visual_pivot:
		visual_pivot.position.y = -display_z

	if shadow_sprite:
		shadow_sprite.visible = _should_show_shadow()

func _get_horizontal_position() -> Vector2:
	if horizontal_movement == null:
		return (
			position_target.position
			if position_target
			else Vector2.ZERO
		)

	if horizontal_movement.has_method(
		"get_horizontal_position"
	):
		return horizontal_movement.get_horizontal_position()

	push_warning(
		"EntityVisualController: " +
		"horizontal_movement 缺少 get_horizontal_position()"
	)

	return Vector2.ZERO


func _get_visual_z_height() -> float:
	if z_movement == null:
		return 0.0

	if not _is_in_air():
		return 0.0

	return maxf(
		z_movement.get_z_height(),
		0.0
	)

func _should_show_shadow() -> bool:
	if z_movement == null:
		return false

	return z_movement.should_show_shadow()
func _is_in_air() -> bool:
	if z_movement == null:
		return false

	return z_movement.is_in_air
