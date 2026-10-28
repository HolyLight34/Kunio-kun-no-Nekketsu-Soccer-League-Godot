
@tool
class_name HitBox
extends Area2D


# ==============================================================================
# HitBox
#
# 职责：
# 1. 根据 FC Shape ID 更新 CollisionShape2D。
# 2. 根据朝向更新 XY 碰撞区域。
# 3. 通过 Area2D 检测 HurtBox 的 XY 重叠。
# 4. 在统一逻辑步中持续检查 Z 轴重叠。
# 5. 三轴接触开始和结束时分别发出信号，并传递对方所属对象。
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
## target 是对方 HurtBox 所属的对象。
signal contact_started(target: Node)

## 已经成立的三轴接触不再成立时发出。
## target 是本次接触结束的对象。
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

## 是否在编辑器中显示标签。
@export var show_shape_label: bool = true:
	set(value):
		if show_shape_label == value:
			return

		show_shape_label = value
		queue_redraw()


## 标签相对于 HitBox 自身原点的偏移。
@export var label_offset: Vector2 = Vector2(0, -4):
	set(value):
		if label_offset == value:
			return

		label_offset = value
		queue_redraw()


## 标签字号。
@export_range(6, 32, 1)
var label_font_size: int = 10:
	set(value):
		if label_font_size == value:
			return

		label_font_size = value
		queue_redraw()


## HitBox 标签颜色。
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


## 当前处于 XY 重叠范围内的 HurtBox。
var _target_hurt_box: HitBox = null


## 当前已经确认三轴接触的对方对象。
## 独立保存，确保接触结束时仍能识别原来的目标。
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
##
## a_height、b_height：双方当前的 Z 高度。
## a_bounds、b_bounds：双方 Shape 相对于自身高度的区间。
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
## 该状态由 logic_tick() 更新。
func is_contacting() -> bool:
	return _is_contacting

func get_z_bounds() -> Vector2:
	var shape: FCShape = shape_library.get_shape(shape_id)
	return FCShapeParser.get_z_bounds(shape)
# ==============================================================================
# 接触检测
# ==============================================================================

## 由统一逻辑步调度器调用。
##
## XY 重叠期间，每个逻辑步检查 Z 轴。
## 三轴接触开始时发出 contact_started。
## 三轴接触结束时发出 contact_ended。
## 持续接触期间不重复发送开始事件。
func logic_tick() -> void:
	if not is_inside_tree():
		return

	if not monitoring:
		_end_contact()
		return

	if not is_instance_valid(_target_hurt_box):
		_end_contact()
		return

	var target: Node = _target_hurt_box.source

	if not is_instance_valid(target):
		_end_contact()
		return

	var source_height: int = source.get_z_height_integer()
	var target_height: int = target.get_z_height_integer()

	var hurt_z: Vector2 = _target_hurt_box.get_z_bounds()

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


## 建立一次新的三轴接触。
func _begin_contact() -> void:
	if _is_contacting:
		return

	if not is_instance_valid(_target_hurt_box):
		return

	var target: Node = _target_hurt_box.source

	if not is_instance_valid(target):
		return

	# 先记录接触状态，再发送通知。
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

	# 对象已释放时不再发送无效目标。
	if is_instance_valid(previous_target):
		contact_ended.emit(previous_target)


# ==============================================================================
# XY 接触检测
# ==============================================================================

func _on_area_entered(area: Area2D) -> void:
	print("你好",area)
	if area is not HitBox:
		return

	var hurt_box := area as HitBox

	# 排除自身。
	if hurt_box.source == source:
		return

	# 当前设计只跟踪一个目标。
	# 如果已经有有效目标，不覆盖现有目标。
	if is_instance_valid(_target_hurt_box):
		return

	_target_hurt_box = hurt_box


func _on_area_exited(area: Area2D) -> void:
	if area != _target_hurt_box:
		return

	# XY 离开意味着三轴接触也已经结束。
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

	# 更新 Shape 后开启检测。
	monitoring = true


## 关闭检测并清除接触状态。
func _disable_detection() -> void:
	_end_contact()

	hit_z_bounds = Vector2.ZERO

	if not is_node_ready():
		return

	collision_shape.shape = null
	monitoring = false

	_target_hurt_box = null
	_contact_target = null
	_is_contacting = false


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
