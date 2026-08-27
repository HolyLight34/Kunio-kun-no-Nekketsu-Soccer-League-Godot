# ==============================================================================
# EntityVisualController.gd
#
# 通用实体表现同步组件
#
# 作用：
#   读取 HorizontalMovement 与 ZMovement 的最终物理状态，
#   并同步到实际显示节点。
#
# 适用于：
#   Player
#   Ball
#
# 数据流：
#
#   HorizontalMovement
#           │
#           │ XY
#           ↓
#   EntityVisualController
#           ↑
#           │ Z
#           │
#      ZMovement
#
#
# 重要：
#   本组件只读取物理状态。
#   不修改 HorizontalMovement / ZMovement 内部数据。
#
#
# 插值：
#
#   FC Logic Tick 更新一次真实物理数据。
#
#   previous_state
#         ↓
#      插值显示
#         ↓
#   target_state
#
#   插值只影响表现，不影响物理、碰撞、状态机和 FC 数据。
# ==============================================================================

extends Node
class_name EntityVisualController
# ==============================================================================
# 配置
# ==============================================================================
## 一个 FC Logic Tick 对应多少个 Godot Physics Frame。
##
## 例如：
##
## Godot Physics = 60 Hz
## FC Logic      ≈ 每 3 个 Physics Frame 更新一次
##
## 那么视觉层会在这 3 帧之间进行插值。
const PHYSICS_FRAMES_PER_LOGIC_TICK: int = 3
# ==============================================================================
# 物理组件
# ==============================================================================
@export_group("Movement Components")
## 水平移动组件。
##
## 需要提供：
##
## get_horizontal_position() -> Vector2
@export var horizontal_movement: Node
## Z轴移动组件。
##
## 需要提供：
##
## get_z_height() -> float
## is_in_air: bool
@export var z_movement: ZMovementBase
# ==============================================================================
# 视觉节点
# ==============================================================================
@export_group("Visual Nodes")
## 实体地面 XY 位置的节点。
##
## 通常可以直接绑定：
##
## Player
##
## 或
##
## Ball
##
## Z高度不会修改这个节点。
@export var position_target: Node2D
## 只负责视觉 Z 高度偏移的节点。
##
## 推荐场景：
##
## Player
## ├── VisualPivot
## │   └── Sprite
## └── Shadow
##
## VisualPivot.position.y = -Z
@export var visual_pivot: Node2D
## 阴影节点。
##
## 阴影保持在地面，不随 Z 高度上升。
@export var shadow_sprite: Sprite2D
# ==============================================================================
# 显示配置
# ==============================================================================
@export_group("Rendering")
## 是否开启逻辑 Tick 之间的视觉插值。
##
## true：
##
## 物理：
##
## 100 ---------- 106
##
## 显示：
##
## 100 -> 102 -> 104 -> 106
##
##
## false：
##
## 直接显示当前物理位置。
##
## 方便和 FC / Mesen 对照。
@export var interpolation_enabled: bool = true
## 是否保留物理子像素进行显示。
##
## true：
##
## 100.375
##
## 会直接显示 100.375。
##
##
## false：
##
## 最终视觉坐标会取整数。
##
## 注意：
## 只影响显示，不修改物理 raw 数据。
@export var smooth_subpixel_rendering: bool = true
## true：
## 只在空中显示阴影。
##
## false：
## 阴影始终显示。
@export var shadow_only_in_air: bool = false
# ==============================================================================
# 插值状态
# ==============================================================================
## 当前插值进行到第几个 Physics Frame。
var interpolation_frame: int = 0
## 上一个 FC Logic Tick 的 XY 视觉状态。
var previous_position: Vector2 = Vector2.ZERO
## 当前 FC Logic Tick 的目标 XY 状态。
var target_position: Vector2 = Vector2.ZERO
## 上一个 FC Logic Tick 的视觉 Z 高度。
var previous_z: float = 0.0
## 当前 FC Logic Tick 的目标视觉 Z 高度。
var target_z: float = 0.0
## 防止第一次同步时从 Vector2.ZERO 插值过去。
# ==============================================================================
# 生命周期
# ==============================================================================
func _physics_process(_delta: float) -> void:
	if not interpolation_enabled:
		_apply_visual_state(
			target_position,
			target_z
		)
		return
	interpolation_frame += 1
	var alpha := minf(
		float(interpolation_frame)
		/ float(PHYSICS_FRAMES_PER_LOGIC_TICK),
		1.0
	)
	var display_position := previous_position.lerp(
		target_position,
		alpha
	)
	var display_z := lerpf(
		previous_z,
		target_z,
		alpha
	)
	_apply_visual_state(
		display_position,
		display_z
	)
# ==============================================================================
# Logic Tick 同步
# ==============================================================================
## 每次 FC Logic Tick 的物理计算全部完成后调用一次。
##
## 推荐调用顺序：
##
## horizontal_movement.process_xxx_step()
## z_movement.process_z_step()
##
## visual_controller.sync_physics_state()
##
##
## 本函数只负责获取新的物理目标值，
## 不直接修改物理组件。
func sync_physics_state() -> void:
	var new_position := _get_horizontal_position()
	var new_z := _get_visual_z_height()
	# 第一次采样时不需要插值。
	#
	# 否则实体可能会：
	#
	# (0,0)
	#   ↓
	# 上一个目标值成为新的插值起点。
	previous_position = target_position
	previous_z = target_z
	# 获取最新物理结果。
	target_position = new_position
	target_z = new_z
	# 从头开始这一段插值。
	interpolation_frame = 0
# ==============================================================================
# 初始化
# ==============================================================================
func initialize() -> void:
	var initial_position := _get_horizontal_position()
	var initial_z := _get_visual_z_height()
	previous_position = initial_position
	target_position = initial_position
	previous_z = initial_z
	target_z = initial_z
	interpolation_frame = PHYSICS_FRAMES_PER_LOGIC_TICK
	_apply_visual_state(
		initial_position,
		initial_z
	)
# ==============================================================================
# 应用最终视觉状态
# ==============================================================================
func _apply_visual_state(
	horizontal_position: Vector2,
	z_height: float
) -> void:
	var display_position := horizontal_position
	var display_z := z_height
	# --------------------------------------------------------------------------
	# 像素显示
	#
	# 这里处理的是最终显示数据。
	#
	# 绝对不要把 floor 后的数据写回物理组件。
	# --------------------------------------------------------------------------
	if not smooth_subpixel_rendering:
		display_position = display_position.floor()
		display_z = floorf(display_z)
	# --------------------------------------------------------------------------
	# XY
	# --------------------------------------------------------------------------
	if position_target:
		position_target.position = display_position
	# --------------------------------------------------------------------------
	# Z
	#
	# Godot Y正方向向下，
	# 所以 Z 高度需要写成负的视觉 Y 偏移。
	# --------------------------------------------------------------------------
	if visual_pivot:
		visual_pivot.position.y = -display_z
	# --------------------------------------------------------------------------
	# 阴影
	# --------------------------------------------------------------------------
	if shadow_sprite:
		if shadow_only_in_air:
			shadow_sprite.visible = _is_in_air()
		else:
			shadow_sprite.visible = true
# ==============================================================================
# 获取水平物理位置
# ==============================================================================
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
# ==============================================================================
# 获取最终视觉 Z 高度
# ==============================================================================
func _get_visual_z_height() -> float:
	if z_movement == null:
		return 0.0
	# --------------------------------------------------------------------------
	# 已经落地
	#
	# 足球物理可能仍然保存：
	#
	# z_height_raw = 127
	#
	# 即：
	#
	# 0.49609375
	#
	# 这是 FC 为下一次反弹保留的物理子像素，
	# 不代表视觉上足球应该悬空。
	# --------------------------------------------------------------------------
	if not _is_in_air():
		return 0.0
	var height := z_movement.get_z_height()
	# --------------------------------------------------------------------------
	# 足球落地检测过程中可能暂时出现 Z < 0。
	#
	# 这种负高度属于物理计算中间状态，
	# 视觉永远不允许显示到地下。
	# --------------------------------------------------------------------------
	return maxf(
		height,
		0.0
	)
# ==============================================================================
# 查询空中状态
# ==============================================================================
func _is_in_air() -> bool:
	if z_movement == null:
		return false
	return z_movement.is_in_air
