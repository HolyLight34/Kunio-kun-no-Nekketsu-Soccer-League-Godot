extends Node
class_name EntityVisualController


# ==============================================================================
# Movement Components
# ==============================================================================

@export_group("Movement Components")

@export var horizontal_movement: Node
@export var z_movement: ZMovementBase


# ==============================================================================
# Visual Nodes
# ==============================================================================

@export_group("Visual Nodes")

## 实体水平位置真正写入的节点。
@export var position_target: Node2D

## 用于表现 Z 高度。
@export var visual_pivot: Node2D

## 地面阴影。
@export var shadow_sprite: Sprite2D


# ==============================================================================
# Rendering
# ==============================================================================

@export_group("Rendering")

## 是否保留子像素显示。
##
## true:
## 例如 10.5703125 会直接用于显示。
##
## false:
## 显示时取整，但不会修改物理 raw 数据。
@export var smooth_subpixel_rendering: bool = true


# ==============================================================================
# 生命周期
# ==============================================================================

func _ready() -> void:
	# 尽量让表现层在物理逻辑完成之后运行。
	process_physics_priority = 100


func _physics_process(_delta: float) -> void:
	_apply_visual_state(
		_get_horizontal_position(),
		_get_visual_z_height()
	)


# ==============================================================================
# 初始化
# ==============================================================================

func initialize() -> void:
	_apply_visual_state(
		_get_horizontal_position(),
		_get_visual_z_height()
	)


# ==============================================================================
# 应用表现
# ==============================================================================

func _apply_visual_state(
	horizontal_position: Vector2,
	z_height: float
) -> void:
	var display_position := horizontal_position
	var display_z := z_height

	if not smooth_subpixel_rendering:
		display_position = display_position.floor()
		display_z = floorf(display_z)

	# XY
	if position_target:
		position_target.position = display_position

	# Z
	if visual_pivot:
		visual_pivot.position.y = -display_z

	# Shadow
	if shadow_sprite:
		shadow_sprite.visible = _should_show_shadow()


# ==============================================================================
# Horizontal
# ==============================================================================

func _get_horizontal_position() -> Vector2:
	if horizontal_movement == null:
		if position_target:
			return position_target.position

		return Vector2.ZERO

	if horizontal_movement.has_method(
		"get_horizontal_position"
	):
		return horizontal_movement.get_horizontal_position()

	push_warning(
		"EntityVisualController: "
		+ "horizontal_movement 缺少 get_horizontal_position()"
	)

	return Vector2.ZERO


# ==============================================================================
# Z
# ==============================================================================

func _get_visual_z_height() -> float:
	if z_movement == null:
		return 0.0

	if not z_movement.is_in_air:
		return 0.0

	return maxf(
		z_movement.get_z_height(),
		0.0
	)


# ==============================================================================
# Shadow
# ==============================================================================

func _should_show_shadow() -> bool:
	if z_movement == null:
		return false

	return z_movement.should_show_shadow()
