
@tool
class_name HitBox
extends Area2D


# ==============================================================================
# HitBox
#
# 职责：
# 1. 根据 FC Shape ID 更新 CollisionShape2D。
# 2. 根据朝向更新 XY 碰撞区域。
# 3. 在统一逻辑步中主动查询 XY 重叠。
# 4. 在统一逻辑步中检查 Z 轴重叠。
# 5. 三轴接触开始和结束时分别发出信号。
# 6. 在编辑器中显示 HIT Shape 标签和 Z 轴区间。
#
# 不负责：
# - 判断攻击是否命中。
# - 计算伤害或体力差。
# - 处理受伤、接球或球权。
# - 决定接触后的行为或状态。
# ==============================================================================


# ==============================================================================
# 信号
# ==============================================================================

## XY 与 Z 轴首次同时满足接触条件时发出。
signal contact_started(target: Node)

## 已经成立的三轴接触不再成立时发出。
signal contact_ended(target: Node)


# ==============================================================================
# 配置
# ==============================================================================

## 发出这个 HitBox 的对象。
@export var source: CharacterBody2D


## FC Shape 数据库。
@export var shape_library: FCShapeLibrary:
	set(value):
		if shape_library == value:
			return

		_disconnect_shape()
		shape_library = value
		_connect_shape()
		_apply_shape()


## 当前使用的 FC Shape 编号。
## -1 表示没有检测区域。
@export_range(-1, 255, 1)
var shape_id: int = -1:
	set(value):
		if shape_id == value:
			return

		_disconnect_shape()
		shape_id = value
		_connect_shape()
		_apply_shape()


## 当前对象是否朝左。
@export var facing_left: bool = false:
	set(value):
		if facing_left == value:
			return

		facing_left = value
		_apply_shape()


# ==============================================================================
# 标签显示配置
# ==============================================================================

@export var show_shape_label: bool = true:
	set(value):
		if show_shape_label == value:
			return

		show_shape_label = value
		queue_redraw()


@export var label_offset: Vector2 = Vector2(0, -4):
	set(value):
		if label_offset == value:
			return

		label_offset = value
		queue_redraw()


@export_range(6, 32, 1)
var label_font_size: int = 10:
	set(value):
		if label_font_size == value:
			return

		label_font_size = value
		queue_redraw()


@export var label_color: Color = Color(1.0, 0.55, 0.15, 1.0):
	set(value):
		if label_color == value:
			return

		label_color = value
		queue_redraw()


# ==============================================================================
# 节点
# ==============================================================================

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# ==============================================================================
# 状态
# ==============================================================================

## 当前监听的 FC Shape 资源。
var _connected_shape: FCShape = null


## 当前 HitBox 的 Z 轴区间。
var hit_z_bounds: Vector2 = Vector2.ZERO


## 当前 XY 重叠的 HurtBox。
var _target_hurt_box: HitBox = null


## 当前已经确认三轴接触的对方对象。
var _contact_target: Node = null


## 当前是否已经建立三轴接触。
var _is_contacting: bool = false


# ==============================================================================
# 生命周期
# ==============================================================================

func _ready() -> void:
	_connect_shape()
	_apply_shape()


func _exit_tree() -> void:
	_disconnect_shape()


## 开启或关闭交互。
func set_interaction_enabled(value: bool) -> void:
	monitorable = value
	monitoring = value


# ==============================================================================
# Shape 资源监听
# ==============================================================================

func _connect_shape() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return

	if shape_library == null or shape_id < 0:
		return

	var shape: FCShape = shape_library.get_shape(shape_id)

	if shape == null:
		return

	_connected_shape = shape

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
	_apply_shape()


# ==============================================================================
# Z 轴判定
# ==============================================================================

## 判断双方的实际 Z 轴区间是否重叠。
func overlaps_z(
	a_height: int,
	a_bounds: Vector2,
	b_height: int,
	b_bounds: Vector2
) -> bool:
	var a_min := a_height + a_bounds.x
	var a_max := a_height + a_bounds.y

	var b_min := b_height + b_bounds.x
	var b_max := b_height + b_bounds.y

	return a_min <= b_max and b_min <= a_max


# ==============================================================================
# 接触状态查询
# ==============================================================================

## 返回当前是否已经确认三轴接触。
func is_contacting() -> bool:
	return _is_contacting


func get_z_bounds() -> Vector2:
	var shape: FCShape = shape_library.get_shape(shape_id)
	return FCShapeParser.get_z_bounds(shape)


# ==============================================================================
# 接触检测
# ==============================================================================

## 每个 FC Logic Tick 调用一次。
##
## 1. 主动查询当前 XY 重叠对象。
## 2. 更新当前 HurtBox。
## 3. 检查双方 Z 轴是否重叠。
## 4. 判断接触开始或结束。
func logic_tick() -> void:
	if not is_inside_tree():
		return

	if not monitoring:
		_clear_target()
		return

	# 主动获取当前 XY 重叠对象。
	var next_target := _find_target_hurt_box()

	# 目标发生变化。
	if next_target != _target_hurt_box:
		_end_contact()
		_target_hurt_box = next_target

	# 当前没有 XY 重叠对象。
	if not is_instance_valid(_target_hurt_box):
		_target_hurt_box = null
		_end_contact()
		return

	var target: Node = _target_hurt_box.source

	if not is_instance_valid(target):
		_clear_target()
		return

	# 获取双方当前 Z 高度。
	var source_height: int = source.get_z_height_integer()
	var target_height: int = target.get_z_height_integer()

	var hurt_z: Vector2 = _target_hurt_box.get_z_bounds()

	# 检查 Z 轴重叠。
	var overlapping := overlaps_z(
		source_height,
		hit_z_bounds,
		target_height,
		hurt_z
	)

	if overlapping:
		if not _is_contacting:
			_begin_contact()
	else:
		_end_contact()


# ==============================================================================
# 主动 XY 查询
# ==============================================================================

## 查询当前 HitBox 重叠的其他 Area2D。
##
## 返回值：
## 当前物理空间中与本 HitBox 重叠的 Area2D 查询结果。
func query_overlapping_areas() -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	if not is_inside_tree():
		return results

	if collision_shape.shape == null:
		return results

	var query := PhysicsShapeQueryParameters2D.new()

	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false

	# 排除自身。
	query.exclude = [get_rid()]

	var space_state := get_world_2d().direct_space_state

	results = space_state.intersect_shape(
		query,
		32
	)

	return results


## 从主动查询结果中寻找一个有效的 HurtBox。
func _find_target_hurt_box() -> HitBox:
	var results := query_overlapping_areas()

	for result in results:
		var area := result.get("collider") as Area2D

		if not is_instance_valid(area):
			continue

		if area is not HitBox:
			continue

		var hurt_box := area as HitBox

		# 排除自身对象。
		if hurt_box.source == source:
			continue

		if not is_instance_valid(hurt_box.source):
			continue

		return hurt_box

	return null


# ==============================================================================
# 接触开始与结束
# ==============================================================================

## 建立一次新的三轴接触。
func _begin_contact() -> void:
	if _is_contacting:
		return

	if not is_instance_valid(_target_hurt_box):
		return

	var target: Node = _target_hurt_box.source

	if not is_instance_valid(target):
		return

	_is_contacting = true
	_contact_target = target

	contact_started.emit(target)


## 结束当前三轴接触。
func _end_contact() -> void:
	if not _is_contacting:
		return

	var previous_target: Node = _contact_target

	# 先清除状态，避免信号回调重入。
	_is_contacting = false
	_contact_target = null

	if is_instance_valid(previous_target):
		contact_ended.emit(previous_target)


## 清除当前目标及接触状态。
func _clear_target() -> void:
	_end_contact()
	_target_hurt_box = null


# ==============================================================================
# Shape 应用
# ==============================================================================

func _apply_shape() -> void:
	queue_redraw()

	if not is_node_ready():
		return

	if shape_library == null or shape_id < 0:
		_disable_detection()
		return

	var fc_shape: FCShape = shape_library.get_shape(shape_id)

	if fc_shape == null or not fc_shape.is_valid():
		push_warning(
			"HitBox: FC Shape not found: $%02X" % shape_id
		)
		_disable_detection()
		return

	var data: Dictionary = FCShapeParser.get_rectangle_data(
		fc_shape,
		not facing_left
	)

	var rectangle_position: Vector2 = data["position"]
	var rectangle_size: Vector2 = data["size"]

	if rectangle_size.x <= 0.0 or rectangle_size.y <= 0.0:
		_disable_detection()
		return

	hit_z_bounds = FCShapeParser.get_z_bounds(fc_shape)

	var rectangle := RectangleShape2D.new()
	rectangle.size = rectangle_size

	collision_shape.shape = rectangle
	collision_shape.position = rectangle_position

	monitoring = true


## 关闭检测并清除接触状态。
func _disable_detection() -> void:
	_clear_target()

	hit_z_bounds = Vector2.ZERO

	if not is_node_ready():
		return

	collision_shape.shape = null
	monitoring = false


# ==============================================================================
# 编辑器标签
# ==============================================================================

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	if not show_shape_label:
		return

	if shape_library == null or shape_id < 0:
		return

	var fc_shape: FCShape = shape_library.get_shape(shape_id)

	if fc_shape == null or not fc_shape.is_valid():
		return

	var label_position: Vector2 = label_offset

	draw_string(
		ThemeDB.fallback_font,
		label_position,
		"HIT $%02X" % shape_id,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		label_font_size,
		label_color
	)

	var z_bounds: Vector2 = FCShapeParser.get_z_bounds(
		fc_shape
	)

	var z_label_position := label_position + Vector2(
		0,
		label_font_size + 4
	)

	draw_string(
		ThemeDB.fallback_font,
		z_label_position,
		"Z: %s ~ %s" % [
			str(z_bounds.x),
			str(z_bounds.y)
		],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		label_font_size,
		label_color
	)
