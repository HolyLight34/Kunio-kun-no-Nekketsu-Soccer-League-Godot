# ==============================================================================
# EntityVisualController.gd
#
# 通用实体视觉同步组件
#
# 作用：
#   读取水平移动组件和 Z 移动组件的最终物理状态，
#   并同步到实际显示节点。
#
# 适用于：
#   Player
#   Ball
#
# 物理层：
#   HorizontalMovement -> X / Y
#   ZMovement          -> Z
#
# 表现层：
#   EntityVisualController
#        ↓
#   visual_root / visual_pivot / shadow
#
# 注意：
#   本组件只读取物理状态，不反向修改物理数据。
# ==============================================================================

extends Node
class_name EntityVisualController
# ==============================================================================
# 物理组件
# ==============================================================================
@export_group("Movement Components")
## 水平移动组件。
##
## 需要提供：
##
## get_position() -> Vector2
##
## 如果你暂时还没统一 Player / Ball 水平组件接口，
## 也可以先不绑定，由外部传位置。
@export var horizontal_movement: Node
## Z轴移动组件。
##
## 需要提供：
##
## get_z_height() -> float
## is_in_air: bool
##
@export var z_movement: ZMovementBase
# ==============================================================================
# 视觉节点
# ==============================================================================
@export_group("Visual Nodes")
## 实体地面位置对应的根节点。
##
## 如果你的 Player / Ball 根节点本身已经由其他地方同步 XY，
## 这里可以不绑定。
@export var position_target: Node2D
## 真正需要随 Z 高度向上偏移的视觉节点。
##
## 例如：
##
## Player
## ├── VisualPivot   <- 绑定这里
## │   └── Sprite
## └── Shadow
##
@export var visual_pivot: Node2D
## 阴影节点。
##
## 阴影保持在地面 XY 位置，不随 Z 上升。
@export var shadow_sprite: Node2D
# ==============================================================================
# 显示配置
# ==============================================================================
@export_group("Rendering")
## true：
##   保留 1/256 子像素显示，移动更平滑。
##
## false：
##   视觉位置取整数，更接近 FC 像素显示。
##
## 注意：
##   这里只影响显示，不修改物理数据。
@export var smooth_subpixel_rendering: bool = true
## 是否只在空中显示阴影。
##
## 如果 false，阴影始终显示。
@export var shadow_only_in_air: bool = false
# ==============================================================================
# 外部接口
# ==============================================================================
## 同步当前物理状态到视觉。
##
## 推荐在：
##
## HorizontalMovement.process_xxx_step()
## ZMovement.process_z_step()
##
## 都执行完成以后调用一次。

func sync_visual() -> void:
	var horizontal_position := _get_horizontal_position()
	print(horizontal_position)
	var visual_height := _get_visual_height()
	# --------------------------------------------------------------------------
	# 是否显示子像素
	# --------------------------------------------------------------------------
	if not smooth_subpixel_rendering:
		horizontal_position = horizontal_position.floor()
		visual_height = floorf(visual_height)
	# --------------------------------------------------------------------------
	# 同步地面 XY
	# --------------------------------------------------------------------------
	if position_target:
		position_target.position = horizontal_position
	# --------------------------------------------------------------------------
	# 同步视觉 Z 高度
	#
	# Z 在 2.5D 中表现为视觉节点向上移动。
	# --------------------------------------------------------------------------
	if visual_pivot:
		visual_pivot.position.y = -visual_height

	# --------------------------------------------------------------------------
	# 阴影
	# --------------------------------------------------------------------------
	if shadow_sprite:
		if shadow_only_in_air:
			shadow_sprite.visible = _is_in_air()
		else:
			shadow_sprite.visible = true

# ==============================================================================
# 获取水平位置
# ==============================================================================
func _get_horizontal_position() -> Vector2:
	if horizontal_movement == null:
		return Vector2.ZERO
	if horizontal_movement.has_method("get_horizontal_position"):
		return horizontal_movement.get_horizontal_position()
	push_warning(
		"EntityVisualController: horizontal_movement 缺少 get_position()"
	)
	return Vector2.ZERO
# ==============================================================================
# 获取视觉 Z 高度
# ==============================================================================
func _get_visual_height() -> float:
	if z_movement == null:
		return 0.0
	# --------------------------------------------------------------------------
	# 已经不在空中：
	#
	# 视觉必须贴地。
	#
	# 例如足球物理可能仍保留：
	#
	# z_height_raw = 127
	# = 0.49609375
	#
	# 这是 FC 的物理子像素余量，
	# 不代表足球视觉上还悬空。
	# --------------------------------------------------------------------------
	if not _is_in_air():
		return 0.0
	if not z_movement.has_method("get_z_height"):
		push_warning(
			"EntityVisualController: z_movement 缺少 get_z_height()"
		)
		return 0.0
	var height: float = z_movement.get_z_height()
	# --------------------------------------------------------------------------
	# 防止物理计算过程中的负 Z 被直接显示。
	#
	# 足球落地时可能先出现：
	#
	# Z < 0
	#
	# 然后在同一物理逻辑步完成：
	#
	# 子像素修正
	# 反弹计算
	#
	# 即使调用时机出现问题，视觉也不会陷入地下。
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
