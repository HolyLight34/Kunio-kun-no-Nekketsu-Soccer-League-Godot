class_name VisualComponent
extends Node2D


## VisualComponent
##
## 游戏实体通用的视觉根组件。
##
## 本组件负责所有实体共有的视觉空间变换。
##
## 当前职责：
##
## - 将逻辑 Z 高度转换为画面上的 Y 轴偏移
## - 对整个实体视觉进行水平翻转
##
## Player、Ball 等实体可以共用本组件。
##
## 本组件不关心自己的子节点具体是什么：
##
## Player 可以放入 PlayerCompositeSprite，
## Ball 可以放入普通 Sprite2D。
##
## 不负责：
##
## - 动画播放
## - SpriteSheet 帧选择
## - Player 的 Body / Head 组合
## - Ball 的具体外观
## - XY / Z 物理计算
## - 游戏状态和规则


# ==============================================================================
# Z 轴视觉表现
# ==============================================================================

## 设置实体的视觉 Z 高度。
##
## 逻辑 Z 高度不会修改实体本身的 XY 位置。
## 本组件只负责把 Z 高度转换成画面上的垂直偏移。
##
## 例如：
##
##     z_height = 0
##     -> position.y = 0
##
##     z_height = 8
##     -> position.y = -8
func set_z_height(z_height: float) -> void:
	position.y = -z_height


# ==============================================================================
# 水平翻转
# ==============================================================================

## 设置视觉水平朝向。
##
## direction < 0：
##     向左
##
## direction > 0：
##     向右
##
## direction == 0：
##     保持当前视觉朝向。
##
## 翻转发生在整个 VisualComponent 上，
## 因此所有子视觉节点都会一起翻转。
func set_horizontal_facing(direction: float) -> void:
	if direction < 0.0:
		scale.x = -absf(scale.x)

	elif direction > 0.0:
		scale.x = absf(scale.x)
