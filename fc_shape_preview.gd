
@tool
class_name FCShapePreview
extends Node2D


@export var shape_library: FCShapeLibrary:
	set(value):
		if shape_library == value:
			return

		_disconnect_shape()
		shape_library = value
		_connect_shape()
		queue_redraw()


@export_range(0, 255, 1)
var shape_id: int = 0:
	set(value):
		if shape_id == value:
			return

		_disconnect_shape()
		shape_id = value
		_connect_shape()
		queue_redraw()


@export var facing_left: bool = true:
	set(value):
		if facing_left == value:
			return

		facing_left = value
		queue_redraw()


@export var show_origin: bool = true:
	set(value):
		if show_origin == value:
			return

		show_origin = value
		queue_redraw()


var _connected_shape: FCShape = null


func _ready() -> void:
	_connect_shape()
	queue_redraw()


func _exit_tree() -> void:
	_disconnect_shape()


func _connect_shape() -> void:
	if not is_node_ready() and not Engine.is_editor_hint():
		return

	if shape_library == null:
		return

	_connected_shape = shape_library.get_shape(shape_id)

	if _connected_shape == null:
		return

	if not _connected_shape.changed.is_connected(
		_on_shape_changed
	):
		_connected_shape.changed.connect(
			_on_shape_changed
		)


func _disconnect_shape() -> void:
	if _connected_shape == null:
		return

	if _connected_shape.changed.is_connected(
		_on_shape_changed
	):
		_connected_shape.changed.disconnect(
			_on_shape_changed
		)

	_connected_shape = null


func _on_shape_changed() -> void:
	queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if show_origin:
		draw_line(
			Vector2(-5, 0),
			Vector2(5, 0),
			Color.WHITE,
			1.0
		)

		draw_line(
			Vector2(0, -5),
			Vector2(0, 5),
			Color.WHITE,
			1.0
		)

	if shape_library == null:
		return

	var shape := shape_library.get_shape(shape_id)

	if shape == null or not shape.is_valid():
		return

	var rectangle_data := FCShapeParser.get_rectangle_data(
		shape,
		facing_left
	)

	var rectangle_position: Vector2 = rectangle_data["position"]
	var rectangle_size: Vector2 = rectangle_data["size"]

	var rectangle := Rect2(
		rectangle_position - rectangle_size * 0.5,
		rectangle_size
	)

	# 矩形轮廓。
	draw_rect(
		rectangle,
		Color(1.0, 0.55, 0.15, 0.9),
		false,
		1.0
	)

	# 淡色填充，方便观察区域。
	draw_rect(
		rectangle,
		Color(1.0, 0.55, 0.15, 0.10),
		true
	)

	# 显示当前 Shape 编号。
	draw_string(
		ThemeDB.fallback_font,
		rectangle.position + Vector2(0, -4),
		"Shape $%02X" % shape_id,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		10,
		Color(1.0, 0.8, 0.5)
	)
