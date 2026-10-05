@tool
class_name PlayerCompositeSprite
extends Node2D


## PlayerCompositeSprite
##
## Player 专用的组合精灵。
##
## FC 角色视觉由 Body 和 Head 两个 Sprite2D 组合而成。
## 本节点负责隐藏这种组合方式，使外部可以像操作普通
## SpriteSheet 一样，通过 frame 选择完整角色画面。
##
## 内部结构：
##
##     PlayerCompositeSprite
##     ├── Body
##     └── Head
##
## 对外主要表现为：
##
##     frame = 0
##     frame = 1
##     frame = 2
##
## 每个 frame 实际对应一个 PlayerCompositeFrame，
## 再由本节点转换为：
##
##     Body.frame
##     Head.frame
##     Head.position
##
## 当 PlayerCompositeFrame.head_frame == NO_HEAD_FRAME 时，
## 当前组合帧不显示 Head。
##
## AnimationPlayer 应只控制本节点的 frame，
## 不应该直接操作 Body 和 Head。
##
## 不负责：
##
## - Z 高度视觉偏移
## - 整体视觉翻转
## - 动画时间
## - Player 状态
## - 物理运动
@onready var head: Sprite2D = $Head
@onready var body: Sprite2D = $Body


# ==============================================================================
# 组合帧数据
# ==============================================================================

## 当前使用的组合视觉帧表。
##
## 可以理解为本节点使用的“虚拟 SpriteSheet”。
@export var sprite_frames: PlayerCompositeSpriteFrames:
	set(value):
		if sprite_frames == value:
			return

		sprite_frames = value
		_update_frame_connection()
		_apply_frame()


# ==============================================================================
# 当前帧
# ==============================================================================

## 当前显示的组合视觉帧编号。
##
## AnimationPlayer 应控制此属性。
##
## 当前 FC 角色组合动画共使用 78 个帧槽：
## 0 ~ 77。
@export_range(0, 77, 1)
var frame: int = 0:
	set(value):
		if frame == value:
			return

		frame = value
		_update_frame_connection()
		_apply_frame()


# ==============================================================================
# 内部节点
# ==============================================================================

## 身体 Sprite。
##
## 属于组合精灵内部实现。
@onready var _body_sprite: Sprite2D = $Body


## 头部 Sprite。
##
## 属于组合精灵内部实现。
@onready var _head_sprite: Sprite2D = $Head


# ==============================================================================
# 内部状态
# ==============================================================================

## 当前正在显示的组合帧。
##
## 保存引用用于监听 Resource.changed，
## 以支持 Godot 编辑器中的实时预览。
var _current_frame_data: PlayerCompositeFrame = null


# ==============================================================================
# 生命周期
# ==============================================================================

func _ready() -> void:
	_update_frame_connection()
	_apply_frame()


# ==============================================================================
# 组合帧内部实现
# ==============================================================================

## 更新当前组合帧的 changed 信号连接。
##
## 当 Inspector 修改当前 PlayerCompositeFrame 时，
## 自动刷新编辑器中的角色预览。
func _update_frame_connection() -> void:
	_disconnect_current_frame()

	_current_frame_data = null

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


## 断开旧组合帧的 changed 信号。
func _disconnect_current_frame() -> void:
	if _current_frame_data == null:
		return

	if _current_frame_data.changed.is_connected(
		_on_frame_data_changed
	):
		_current_frame_data.changed.disconnect(
			_on_frame_data_changed
		)

## 当前组合帧数据发生改变。
##
## 用于 @tool 编辑器实时预览。
func _on_frame_data_changed() -> void:
	_apply_frame()


## 将当前组合帧应用到 Body 和 Head。
func _apply_frame() -> void:
	if not is_node_ready():
		return

	if sprite_frames == null:
		return

	var frame_data := sprite_frames.get_frame(frame)

	if frame_data == null:
		return

	# --------------------------------------------------------------------------
	# Body
	# --------------------------------------------------------------------------

	_body_sprite.frame = frame_data.body_frame

	# --------------------------------------------------------------------------
	# Head
	# --------------------------------------------------------------------------

	_head_sprite.position = frame_data.head_position

	if frame_data.head_frame == PlayerCompositeFrame.NO_HEAD_FRAME:
		_head_sprite.visible = false
		return

	_head_sprite.visible = true
	_head_sprite.frame = frame_data.head_frame
