
@tool
class_name CollisionController
extends Node2D


# ==============================================================================
# Shape Catalog
# ==============================================================================

@export_group("Shape Catalog")

@export var shape_catalog: FCCollisionShapeCatalog:
	set(value):
		if shape_catalog == value:
			return

		shape_catalog = value

		if is_node_ready():
			_apply_all_profiles()


# ==============================================================================
# HitBox：只负责选择当前 Shape
# ==============================================================================

@export_group("HitBox")

@export_range(0, 255, 1)
var hit_box_shape_id: int = 0:
	set(value):
		if hit_box_shape_id == value:
			return

		hit_box_shape_id = value

		if is_node_ready():
			_refresh_profile_connections()
			_apply_hit_box()


# ==============================================================================
# HurtBox：只负责选择当前 Shape
# ==============================================================================

@export_group("HurtBox")

@export_range(0, 255, 1)
var hurt_box_shape_id: int = 0:
	set(value):
		if hurt_box_shape_id == value:
			return

		hurt_box_shape_id = value

		if is_node_ready():
			_refresh_profile_connections()
			_apply_hurt_box()


# ==============================================================================
# 编辑器设置
# ==============================================================================

@export_group("Collision Editor")

@export var show_collision_editors: bool = true:
	set(value):
		if show_collision_editors == value:
			return

		show_collision_editors = value

		if is_node_ready():
			_apply_all_profiles()
			queue_redraw()


## 开启后，可以拖动碰撞框并修改尺寸。
@export var edit_collision_profiles: bool = false


# ==============================================================================
# 内部节点
# ==============================================================================

@onready var _hit_area: Area2D = $HitBoxArea
@onready var _hit_shape: CollisionShape2D = (
	$HitBoxArea/CollisionShape2D
)

@onready var _hurt_area: Area2D = $HurtBoxArea
@onready var _hurt_shape: CollisionShape2D = (
	$HurtBoxArea/CollisionShape2D
)


# ==============================================================================
# 内部状态
# ==============================================================================

var _is_applying: bool = false
var _is_syncing: bool = false

var _connected_profiles: Array[FCCollisionRegionProfile] = []

var _last_hit_shape_position: Vector2 = Vector2.ZERO
var _last_hit_size: Vector2 = Vector2.ZERO

var _last_hurt_shape_position: Vector2 = Vector2.ZERO
var _last_hurt_size: Vector2 = Vector2.ZERO


# ==============================================================================
# 生命周期
# ==============================================================================

func _ready() -> void:
	_ensure_rectangle(_hit_shape)
	_ensure_rectangle(_hurt_shape)

	# 编辑器只负责预览和编辑，不参与真实碰撞检测。
	if Engine.is_editor_hint():
		_disable_editor_detection(_hit_area)
		_disable_editor_detection(_hurt_area)

	_refresh_profile_connections()
	_apply_all_profiles()

	set_process(Engine.is_editor_hint())


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	_sync_editor_changes()


func _disable_editor_detection(area: Area2D) -> void:
	area.monitoring = false
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 0


# ==============================================================================
# 对外接口
# ==============================================================================

## 获取当前 HitBox 使用的几何配置。
func get_current_hit_box_data() -> FCCollisionRegionProfile:
	if shape_catalog == null:
		return null

	return shape_catalog.get_profile(hit_box_shape_id)


## 获取当前 HurtBox 使用的几何配置。
func get_current_hurt_box_data() -> FCCollisionRegionProfile:
	if shape_catalog == null:
		return null

	return shape_catalog.get_profile(hurt_box_shape_id)


## 根据编号查询几何配置。
func get_shape_data(
	shape_id: int
) -> FCCollisionRegionProfile:
	if shape_catalog == null:
		return null

	return shape_catalog.get_profile(shape_id)


## 检查指定编号是否存在。
func has_shape(shape_id: int) -> bool:
	return get_shape_data(shape_id) != null


# ==============================================================================
# 应用当前 Shape
# ==============================================================================

func _apply_all_profiles() -> void:
	if not is_node_ready():
		return

	_refresh_profile_connections()

	_is_applying = true

	_apply_hit_box()
	_apply_hurt_box()

	_is_applying = false

	queue_redraw()


func _apply_hit_box() -> void:
	if not is_node_ready():
		return

	_apply_profile(
		_hit_area,
		_hit_shape,
		get_current_hit_box_data()
	)

	_remember_hit_state()
	queue_redraw()


func _apply_hurt_box() -> void:
	if not is_node_ready():
		return

	_apply_profile(
		_hurt_area,
		_hurt_shape,
		get_current_hurt_box_data()
	)

	_remember_hurt_state()
	queue_redraw()


func _apply_profile(
	area: Area2D,
	collision_shape: CollisionShape2D,
	profile: FCCollisionRegionProfile
) -> void:
	# 没有对应的 Shape 时，关闭该区域。
	if profile == null:
		area.monitoring = false
		area.monitorable = false
		area.visible = false
		collision_shape.disabled = true
		return

	var rectangle := _get_rectangle(collision_shape)

	if rectangle == null:
		return

	# Area2D 始终位于角色原点。
	area.position = Vector2.ZERO

	# 几何位置和尺寸全部来自 Shape Profile。
	collision_shape.position = profile.position
	rectangle.size = profile.size

	if Engine.is_editor_hint():
		_disable_editor_detection(area)

		area.visible = show_collision_editors
		collision_shape.disabled = true
	else:
		# 有有效 Shape 就保持区域启用。
		# 是否执行攻击响应由外部游戏逻辑决定。
		area.visible = true
		collision_shape.disabled = false
		area.monitoring = true
		area.monitorable = true


# ==============================================================================
# 矩形形状初始化
# ==============================================================================

func _ensure_rectangle(
	collision_shape: CollisionShape2D
) -> void:
	if collision_shape.shape == null:
		collision_shape.shape = RectangleShape2D.new()
		return

	if not (collision_shape.shape is RectangleShape2D):
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
# 编辑器状态记录
# ==============================================================================

func _remember_hit_state() -> void:
	_last_hit_shape_position = _hit_shape.position

	var rectangle := _get_rectangle(_hit_shape)

	if rectangle != null:
		_last_hit_size = rectangle.size


func _remember_hurt_state() -> void:
	_last_hurt_shape_position = _hurt_shape.position

	var rectangle := _get_rectangle(_hurt_shape)

	if rectangle != null:
		_last_hurt_size = rectangle.size


# ==============================================================================
# 编辑器拖动与尺寸修改
# ==============================================================================

func _sync_editor_changes() -> void:
	if not edit_collision_profiles:
		return

	if _is_applying or _is_syncing:
		return

	if shape_catalog == null:
		return

	_is_syncing = true

	_sync_profile(
		_hit_shape,
		get_current_hit_box_data(),
		true
	)

	_sync_profile(
		_hurt_shape,
		get_current_hurt_box_data(),
		false
	)

	_is_syncing = false


func _sync_profile(
	collision_shape: CollisionShape2D,
	profile: FCCollisionRegionProfile,
	is_hit_box: bool
) -> void:
	if profile == null:
		return

	var rectangle := _get_rectangle(collision_shape)

	if rectangle == null:
		return

	var new_position := collision_shape.position
	var new_size := rectangle.size

	var last_position: Vector2
	var last_size: Vector2

	if is_hit_box:
		last_position = _last_hit_shape_position
		last_size = _last_hit_size
	else:
		last_position = _last_hurt_shape_position
		last_size = _last_hurt_size

	var changed := (
		not new_position.is_equal_approx(last_position)
		or not new_size.is_equal_approx(last_size)
	)

	if not changed:
		return

	# 只把真正发生变化的数据写回资源。
	if not profile.position.is_equal_approx(new_position):
		profile.position = new_position

	if not profile.size.is_equal_approx(new_size):
		profile.size = new_size

	# 不重置正在拖动的节点位置，避免拖动反馈循环。
	if is_hit_box:
		_remember_hit_state()
	else:
		_remember_hurt_state()

	queue_redraw()


# ==============================================================================
# Resource 变化监听
# ==============================================================================

func _refresh_profile_connections() -> void:
	var desired: Array[FCCollisionRegionProfile] = []

	var candidates: Array[FCCollisionRegionProfile] = [
		get_current_hit_box_data(),
		get_current_hurt_box_data()
	]

	for profile in candidates:
		if profile == null:
			continue

		if not desired.has(profile):
			desired.append(profile)

	# 断开不再使用的配置。
	for old_profile in _connected_profiles:
		if desired.has(old_profile):
			continue

		if old_profile.changed.is_connected(_on_profile_changed):
			old_profile.changed.disconnect(_on_profile_changed)

	# 连接当前使用的配置。
	for new_profile in desired:
		if not new_profile.changed.is_connected(_on_profile_changed):
			new_profile.changed.connect(_on_profile_changed)

	_connected_profiles = desired


func _on_profile_changed() -> void:
	if _is_syncing or _is_applying:
		return

	# 编辑器正在拖动时，不反向重置正在编辑的节点。
	if Engine.is_editor_hint() and edit_collision_profiles:
		return

	_apply_all_profiles()
