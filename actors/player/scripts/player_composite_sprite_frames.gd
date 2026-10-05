@tool
class_name PlayerCompositeSpriteFrames
extends Resource


## PlayerCompositeSpriteFrames
##
## 保存 Player 可以使用的全部组合视觉帧。
##
## 可以把本资源理解成 Player 的“虚拟 SpriteSheet”：
##
##     frames[0] -> 完整角色帧 0
##     frames[1] -> 完整角色帧 1
##     frames[2] -> 完整角色帧 2
##
## 每个元素都是一个 PlayerCompositeFrame。
##
## AnimationPlayer 不需要知道 Body / Head 如何组合，
## 只需要控制 PlayerCompositeSprite.frame。


## 所有组合视觉帧。
@export var frames: Array[PlayerCompositeFrame] = []


## 获取指定编号的组合视觉帧。
##
## 编号无效时返回 null。
func get_frame(index: int) -> PlayerCompositeFrame:
	if index < 0 or index >= frames.size():
		return null

	return frames[index]
