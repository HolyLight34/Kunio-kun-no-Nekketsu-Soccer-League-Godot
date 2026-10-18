
@tool
class_name PlayerCompositeSprite
extends Node2D


## Player 组合精灵。
##
## 负责：
## - 组合 Body / Head 视觉。
## - 根据当前组合帧加载碰撞配置。
## - 在编辑器中编辑 HitBox / HurtBox。
## - 将编辑器代理的修改写回 Profile。
## - 对外提供经过朝向转换的碰撞数据。
## - 在编辑器中显示当前帧的 Collision Z Range。


# ==============================================================================
# 编辑器配置
# ==============================================================================

@export_group("Collision Editor")


## 是否显示碰撞框编辑代理。
@export var show_collision_editors: bool = true:
	set(value):
		if show_collision_editors == value:
			return

		show_collision_editors = value

		if is_node_ready():
			_apply_collision_profiles()
			queue_redraw()


## 是否允许编辑碰撞框并将修改写回 Profile。
@export var edit_collision_profiles: bool = false


## 是否显示 Z 轴范围信息框。
@export var show_z_info: bool = true:
	set(value):
		if show_z_info == value:
			return

		show_z_info = value
		queue_redraw()


## Z 信息框相对于 PlayerCompositeSprite 原点的位置。
##
## X 正数向右，Y 负数向上。
@export var z_info_position: Vector2 = Vector2(40, -70):
	set(value):
		if z_info_position == value:
			return

		z_info_position = value
		queue_redraw()


# ==============================================================================
# 内部节点
# ==============================================================================

@onready var _body_sprite: Sprite2D = get_node_or_null("Body")
@onready var _head_sprite: Sprite2D = get_node_or_null("Head")

@onready var _hit_editor: Area2D = get_node_or_null("HitBoxEditor")
@onready var _hit_shape: CollisionShape2D = get_node_or_null(
	"HitBoxEditor/CollisionShape2D"
)

@onready var _hurt_editor: Area2D = get_node_or_null("HurtBoxEditor")
@onready var _hurt_shape: CollisionShape2D = get_node_or_null(
	"HurtBoxEditor/CollisionShape2D"
)


# ==============================================================================
# 组合帧资源
# ==============================================================================

@export var sprite_frames: PlayerCompositeSpriteFrames:
	set(value):
		if sprite_frames == value:
			return

		# 切换资源前，先保存当前正在编辑的碰撞框。
		_sync_editor_changes_to_profiles()
		_disconnect_current_resources()

		sprite_frames = value

		_update_frame_connection()
		_apply_frame()
		_apply_collision_profiles()
		queue_redraw()


# ==============================================================================
# 当前帧
# ==============================================================================

@export_range(0, 77, 1)
var frame: int = 0:
	set(value):
		if frame == value:
			return

		# 切换帧前保存当前帧的编辑结果。
		_sync_editor_changes_to_profiles()

		frame = value

		_update_frame_connection()
		_apply_frame()
		_apply_collision_profiles()
		queue_redraw()


# ==============================================================================
# 当前资源
# ==============================================================================

var _current_frame_data: PlayerCompositeFrame = null

var _connected_hit_profile: HitBoxProfile = null
var _connected_hurt_profile: HurtBoxProfile = null


## 防止写入 Profile 时重复处理资源通知。
var _is_syncing_profiles: bool = false

## 防止应用 Profile 时被误认为用户正在编辑。
var _is_applying_profiles: bool = false


# ==============================================================================
# 上一次编辑器代理状态
# ==============================================================================

var _last_hit_editor_position: Vector2 = Vector2.ZERO
var _last_hit_shape_position: Vector2 = Vector2.ZERO
var _last_hit_size: Vector2 = Vector2.ZERO

var _last_hurt_editor_position: Vector2 = Vector2.ZERO
var _last_hurt_shape_position: Vector2 = Vector2.ZERO
var _last_hurt_size: Vector2 = Vector2.ZERO


# ==============================================================================
# 生命周期
# ==============================================================================

func _ready() -> void:
	# 编辑器代理不参与游戏实际碰撞。
	for editor_area: Area2D in [_hit_editor, _hurt_editor]:
		if not is_instance_valid(editor_area):
			continue

		editor_area.monitoring = false
		editor_area.monitorable = false
		editor_area.collision_layer = 0
		editor_area.collision_mask = 0

	_ensure_editor_shape(_hit_shape)
	_ensure_editor_shape(_hurt_shape)

	_update_frame_connection()
	_apply_frame()
	_apply_collision_profiles()

	set_process(Engine.is_editor_hint())
	queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	_sync_editor_changes_to_profiles()


# ==============================================================================
# 对外接口：获取当前帧碰撞数据
# ==============================================================================

## 获取当前帧经过朝向转换的 HitBox 数据。
##
## 返回：
## - CollisionFrameData：当前帧存在 HitBoxProfile。
## - null：当前帧没有 HitBoxProfile。
##
## 不修改原始 Profile。
func get_current_hit_box_data() -> CollisionFrameData:
	if _current_frame_data == null:
		return null

	var profile := _current_frame_data.hit_box_profile

	if profile == null:
		return null

	var result := _build_collision_frame_data(
		profile.enabled,
		profile.position,
		profile.size,
		profile.z_min,
		profile.z_max
	)

	return result


## 获取当前帧经过朝向转换的 HurtBox 数据。
##
## 返回：
## - CollisionFrameData：当前帧存在 HurtBoxProfile。
## - null：当前帧没有 HurtBoxProfile。
##
## 不修改原始 Profile。
func get_current_hurt_box_data() -> CollisionFrameData:
	if _current_frame_data == null:
		return null

	var profile := _current_frame_data.hurt_box_profile

	if profile == null:
		return null

	var result := _build_collision_frame_data(
		profile.enabled,
		profile.position,
		profile.size,
		profile.z_min,
		profile.z_max
	)

	return result


## 根据当前 PlayerCompositeSprite 的水平缩放方向，
## 构建可供运行时碰撞组件直接使用的数据。
##
## 当前约定：
## - scale.x >= 0：保持原始 X 坐标。
## - scale.x < 0：镜像 X 坐标。
##
## 注意：原始 Profile 始终保持不变。
func _build_collision_frame_data(
	profile_enabled: bool,
	profile_position: Vector2,
	profile_size: Vector2,
	profile_z_min: int,
	profile_z_max: int
) -> CollisionFrameData:
	var result := CollisionFrameData.new()

	result.enabled = profile_enabled
	result.position = profile_position
	result.size = profile_size
	result.z_min = profile_z_min
	result.z_max = profile_z_max

	# 仅转换位置，不修改 Profile。
	if scale.x < 0.0:
		result.position.x = -result.position.x

	return result


# ==============================================================================
# 形状初始化
# ==============================================================================

func _ensure_editor_shape(
	collision_shape: CollisionShape2D
) -> void:
	if not is_instance_valid(collision_shape):
		return

	if collision_shape.shape == null:
		collision_shape.shape = RectangleShape2D.new()
	elif not (collision_shape.shape is RectangleShape2D):
		push_warning(
			"%s 必须使用 RectangleShape2D。" %
			collision_shape.get_path()
		)


func _get_rectangle(
	collision_shape: CollisionShape2D
) -> RectangleShape2D:
	if not is_instance_valid(collision_shape):
		return null

	return collision_shape.shape as RectangleShape2D


# ==============================================================================
# 资源信号连接
# ==============================================================================

func _update_frame_connection() -> void:
	_disconnect_current_resources()

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

	_connected_hit_profile = _current_frame_data.hit_box_profile
	_connected_hurt_profile = _current_frame_data.hurt_box_profile

	if _connected_hit_profile != null:
		if not _connected_hit_profile.changed.is_connected(
			_on_profile_changed
		):
			_connected_hit_profile.changed.connect(
				_on_profile_changed
			)

	if _connected_hurt_profile != null:
		if not _connected_hurt_profile.changed.is_connected(
			_on_profile_changed
		):
			_connected_hurt_profile.changed.connect(
				_on_profile_changed
			)


func _disconnect_current_resources() -> void:
	if (
		_current_frame_data != null
		and _current_frame_data.changed.is_connected(
			_on_frame_data_changed
		)
	):
		_current_frame_data.changed.disconnect(
			_on_frame_data_changed
		)

	for profile in [
		_connected_hit_profile,
		_connected_hurt_profile
	]:
		if (
			profile != null
			and profile.changed.is_connected(
				_on_profile_changed
			)
		):
			profile.changed.disconnect(_on_profile_changed)

	_current_frame_data = null
	_connected_hit_profile = null
	_connected_hurt_profile = null


func _on_frame_data_changed() -> void:
	_update_frame_connection()
	_apply_frame()
	_apply_collision_profiles()
	queue_redraw()


func _on_profile_changed() -> void:
	if _is_syncing_profiles or _is_applying_profiles:
		return

	# 资源修改后立即更新编辑器代理与信息框。
	_apply_collision_profiles()
	queue_redraw()


# ==============================================================================
# 应用视觉帧
# ==============================================================================

func _apply_frame() -> void:
	if not is_node_ready():
		return

	if (
		not is_instance_valid(_body_sprite)
		or not is_instance_valid(_head_sprite)
	):
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


# ==============================================================================
# 应用 Profile 到编辑器代理
# ==============================================================================

func _apply_collision_profiles() -> void:
	if not is_node_ready():
		return

	if (
		not is_instance_valid(_hit_editor)
		or not is_instance_valid(_hit_shape)
		or not is_instance_valid(_hurt_editor)
		or not is_instance_valid(_hurt_shape)
	):
		queue_redraw()
		return

	_is_applying_profiles = true

	# 运行时不显示编辑器代理。
	if not Engine.is_editor_hint() or not show_collision_editors:
		_hit_editor.visible = false
		_hurt_editor.visible = false
		_is_applying_profiles = false
		queue_redraw()
		return

	if _current_frame_data == null:
		_hit_editor.visible = false
		_hurt_editor.visible = false
		_is_applying_profiles = false
		queue_redraw()
		return

	var hit_profile := _current_frame_data.hit_box_profile
	var hurt_profile := _current_frame_data.hurt_box_profile

	_hit_editor.visible = hit_profile != null
	_hurt_editor.visible = hurt_profile != null

	if hit_profile != null:
		_hit_editor.position = hit_profile.position
		_hit_shape.position = Vector2.ZERO

		var hit_rectangle := _get_rectangle(_hit_shape)

		if hit_rectangle != null:
			hit_rectangle.size = hit_profile.size

		_remember_hit_state()

	if hurt_profile != null:
		_hurt_editor.position = hurt_profile.position
		_hurt_shape.position = Vector2.ZERO

		var hurt_rectangle := _get_rectangle(_hurt_shape)

		if hurt_rectangle != null:
			hurt_rectangle.size = hurt_profile.size

		_remember_hurt_state()

	_is_applying_profiles = false
	queue_redraw()


# ==============================================================================
# 记录代理状态
# ==============================================================================

func _remember_hit_state() -> void:
	if not is_instance_valid(_hit_editor):
		return

	if not is_instance_valid(_hit_shape):
		return

	_last_hit_editor_position = _hit_editor.position
	_last_hit_shape_position = _hit_shape.position

	var rectangle := _get_rectangle(_hit_shape)

	if rectangle != null:
		_last_hit_size = rectangle.size


func _remember_hurt_state() -> void:
	if not is_instance_valid(_hurt_editor):
		return

	if not is_instance_valid(_hurt_shape):
		return

	_last_hurt_editor_position = _hurt_editor.position
	_last_hurt_shape_position = _hurt_shape.position

	var rectangle := _get_rectangle(_hurt_shape)

	if rectangle != null:
		_last_hurt_size = rectangle.size


# ==============================================================================
# 将编辑器代理修改写回 Profile
# ==============================================================================

func _sync_editor_changes_to_profiles() -> void:
	if not Engine.is_editor_hint():
		return

	if not edit_collision_profiles:
		return

	if not is_node_ready() or _current_frame_data == null:
		return

	if _is_syncing_profiles or _is_applying_profiles:
		return

	if (
		not is_instance_valid(_hit_editor)
		or not is_instance_valid(_hit_shape)
		or not is_instance_valid(_hurt_editor)
		or not is_instance_valid(_hurt_shape)
	):
		return

	_is_syncing_profiles = true

	_sync_hit_profile()
	_sync_hurt_profile()

	_is_syncing_profiles = false


func _sync_hit_profile() -> void:
	var profile := _current_frame_data.hit_box_profile

	if profile == null:
		return

	var rectangle := _get_rectangle(_hit_shape)

	if rectangle == null:
		return

	var parent_position := _hit_editor.position
	var shape_position := _hit_shape.position
	var new_size := rectangle.size

	var changed := (
		not parent_position.is_equal_approx(
			_last_hit_editor_position
		)
		or not shape_position.is_equal_approx(
			_last_hit_shape_position
		)
		or not new_size.is_equal_approx(_last_hit_size)
	)

	if not changed:
		return

	var new_position := parent_position + shape_position

	if not new_position.is_equal_approx(profile.position):
		profile.position = new_position

	if not new_size.is_equal_approx(profile.size):
		profile.size = new_size

	_last_hit_editor_position = parent_position
	_last_hit_shape_position = shape_position
	_last_hit_size = new_size

	queue_redraw()


func _sync_hurt_profile() -> void:
	var profile := _current_frame_data.hurt_box_profile

	if profile == null:
		return

	var rectangle := _get_rectangle(_hurt_shape)

	if rectangle == null:
		return

	var parent_position := _hurt_editor.position
	var shape_position := _hurt_shape.position
	var new_size := rectangle.size

	var changed := (
		not parent_position.is_equal_approx(
			_last_hurt_editor_position
		)
		or not shape_position.is_equal_approx(
			_last_hurt_shape_position
		)
		or not new_size.is_equal_approx(_last_hurt_size)
	)

	if not changed:
		return

	var new_position := parent_position + shape_position

	if not new_position.is_equal_approx(profile.position):
		profile.position = new_position

	if not new_size.is_equal_approx(profile.size):
		profile.size = new_size

	_last_hurt_editor_position = parent_position
	_last_hurt_shape_position = shape_position
	_last_hurt_size = new_size

	queue_redraw()


# ==============================================================================
# Collision Z Range 信息框
# ==============================================================================

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if not show_z_info:
		return

	if _current_frame_data == null:
		return

	var hit_profile := _current_frame_data.hit_box_profile
	var hurt_profile := _current_frame_data.hurt_box_profile

	if hit_profile == null and hurt_profile == null:
		return

	# 固定在 PlayerCompositeSprite 的局部坐标中。
	var box_position := z_info_position
	var box_size := Vector2(168, 64)

	draw_rect(
		Rect2(box_position, box_size),
		Color(0.08, 0.09, 0.12, 0.94),
		true
	)

	draw_rect(
		Rect2(box_position, box_size),
		Color(0.65, 0.68, 0.75, 1.0),
		false,
		1.0
	)

	var font := ThemeDB.fallback_font

	if font == null:
		return

	var font_size := 12

	draw_string(
		font,
		box_position + Vector2(7, 16),
		"Collision Z Range",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.9, 0.9, 0.95)
	)

	var hit_text := "HitBox: "

	if hit_profile != null:
		hit_text += "%d - %d" % [
			hit_profile.z_min,
			hit_profile.z_max
		]
	else:
		hit_text += "--"

	draw_string(
		font,
		box_position + Vector2(7, 35),
		hit_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(1.0, 0.42, 0.42)
	)

	var hurt_text := "HurtBox: "

	if hurt_profile != null:
		hurt_text += "%d - %d" % [
			hurt_profile.z_min,
			hurt_profile.z_max
		]
	else:
		hurt_text += "--"

	draw_string(
		font,
		box_position + Vector2(7, 53),
		hurt_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.35, 0.95, 0.58)
	)
