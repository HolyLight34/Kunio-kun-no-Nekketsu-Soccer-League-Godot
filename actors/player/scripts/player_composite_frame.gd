@tool
class_name PlayerCompositeFrame
extends Resource


## PlayerCompositeFrame
##
## 描述 Player 的一张完整组合视觉帧。
##
## FC 角色画面由 Body 和 Head 两个 Sprite2D 组合而成。
##
## 本资源保存组成一张完整角色视觉帧所需要的数据：
##
## - Body 使用哪个 SpriteSheet 帧
## - Head 使用哪个 SpriteSheet 帧
## - Head 相对于角色视觉原点的位置
##
## 本类只负责描述“这一帧长什么样”。
##
## 不负责：
##
## - 动画播放顺序
## - 动画时间
## - Player 状态
## - 实际 Sprite 显示


# ==============================================================================
# 常量
# ==============================================================================

## 表示当前组合帧不显示 Head。
const NO_HEAD_FRAME: int = -1


# ==============================================================================
# Body
# ==============================================================================

## Body SpriteSheet 中的帧编号。
##
## Body SpriteSheet 共 78 帧，
## 因此合法范围为 0 ~ 77。
@export_range(0, 77, 1)
var body_frame: int = 0:
	set(value):
		if body_frame == value:
			return

		body_frame = value
		emit_changed()


# ==============================================================================
# Head
# ==============================================================================

## Head SpriteSheet 中的帧编号。
##
## -1 表示当前组合帧不显示 Head。
##
## Head SpriteSheet 的最终帧数暂未确定，
## 因此这里只限制最小值。
@export var head_frame: int = 0:
	set(value):
		value = maxi(value, NO_HEAD_FRAME)

		if head_frame == value:
			return

		head_frame = value
		emit_changed()


## Head 相对于 PlayerCompositeSprite 原点的位置。
##
## 使用整数坐标以保持像素画整数像素对齐。
@export var head_position: Vector2i = Vector2i.ZERO:
	set(value):
		if head_position == value:
			return

		head_position = value
		emit_changed()
