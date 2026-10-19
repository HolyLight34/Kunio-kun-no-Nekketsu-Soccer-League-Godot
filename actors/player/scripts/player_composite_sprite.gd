
@tool
class_name PlayerCompositeSprite
extends Node2D


@export var sprite_frames: PlayerCompositeSpriteFrames:
	set(value):
		if sprite_frames == value:
			return

		_disconnect_frame_data()
		sprite_frames = value
		_connect_frame_data()
		_apply_frame()


@export_range(0, 77, 1)
var frame: int = 0:
	set(value):
		if frame == value:
			return

		frame = value
		_connect_frame_data()
		_apply_frame()


@onready var _body_sprite: Sprite2D = $Body
@onready var _head_sprite: Sprite2D = $Head


var _current_frame_data: PlayerCompositeFrame = null


func _ready() -> void:
	_connect_frame_data()
	_apply_frame()


func _disconnect_frame_data() -> void:
	if (
		_current_frame_data != null
		and _current_frame_data.changed.is_connected(
			_on_frame_data_changed
		)
	):
		_current_frame_data.changed.disconnect(
			_on_frame_data_changed
		)

	_current_frame_data = null


func _connect_frame_data() -> void:
	_disconnect_frame_data()

	if sprite_frames == null:
		return

	_current_frame_data = sprite_frames.get_frame(frame)

	if _current_frame_data == null:
		return

	if not _current_frame_data.changed.is_connected(
		_on_frame_data_changed
	):
		_current_frame_data.changed.connect(
			_on_frame_data_changed
		)


func _on_frame_data_changed() -> void:
	_apply_frame()


func _apply_frame() -> void:
	if not is_node_ready():
		return

	if sprite_frames == null:
		return

	var frame_data := sprite_frames.get_frame(frame)

	if frame_data == null:
		return

	_body_sprite.frame = frame_data.body_frame
	_head_sprite.position = Vector2(frame_data.head_position)

	if frame_data.head_frame == PlayerCompositeFrame.NO_HEAD_FRAME:
		_head_sprite.visible = false
	else:
		_head_sprite.visible = true
		_head_sprite.frame = frame_data.head_frame
