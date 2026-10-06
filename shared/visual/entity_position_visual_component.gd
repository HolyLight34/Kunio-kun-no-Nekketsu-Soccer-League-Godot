class_name EntityPositionVisualComponent
extends Node


## EntitySpatialVisualComponent
##
## 负责将实体的逻辑空间状态同步到视觉节点。
##
## 负责：
## - 同步水平显示位置。
## - 根据逻辑 Z 高度调整视觉高度。
## - 同步实体朝向。
## - 控制地面阴影显示。
##
## 不负责：
## - 实体专属动画。
## - 贴图状态切换。
## - Shader 与视觉特效。
## - Player / Ball 的游戏规则。


## 实体的地面位置节点。
##
## 逻辑 XY 位置会直接应用到该节点。
## 阴影等需要停留在地面的视觉节点可以放在该节点之下。
@export var position_target: Node2D


## 实体的视觉高度节点。
##
## Z 高度只作用于该节点，不影响实体的逻辑 XY 位置。
##
## 例如：
##   z_height = 8
##   visual_pivot.position.y = -8
##
## PlayerCompositeSprite、Ball Sprite 等实际视觉节点
## 可以放在该节点之下。
@export var visual_pivot: Node2D


## 实体的阴影视觉节点。
##
## 本组件只负责设置其 visible，
## 不负责判断当前游戏状态是否应该显示阴影。
@export var shadow_sprite: Sprite2D


## 更新实体的视觉位置。
##
## horizontal_position:
##   实体当前的逻辑 XY 位置。
##
## z_height:
##   实体当前的逻辑 Z 高度。
##
## FC 逻辑位置保留子像素精度，但像素画视觉最终对齐到整数像素。
## 这样可以避免 Player 的 Head / Body 等多个独立 Sprite2D
## 在子像素位置渲染时出现接缝。
##
## 此处取整只影响视觉表现，不修改实体的逻辑位置和 Z 高度。
func update_position(
	horizontal_position: Vector2,
	z_height: float
) -> void:
	position_target.position = horizontal_position.round()
	var visual_z: int = floori(z_height)
	visual_pivot.position.y = -visual_z


## 设置实体的视觉朝向。
##
## direction 只使用 X 分量：
##   direction.x < 0 → 朝左
##   direction.x > 0 → 朝右
##   direction.x == 0 → 保持当前视觉朝向
##
## 当前 Player / Ball 的原始视觉素材默认朝左，
## 因此朝左时不翻转，朝右时执行水平翻转。
##
## 本方法只改变视觉朝向，不修改 Player / Ball 的逻辑朝向。
func set_facing_direction(direction: Vector2) -> void:
	if direction.x < 0.0:
		visual_pivot.scale.x = 1.0
	elif direction.x > 0.0:
		visual_pivot.scale.x = -1.0


## 设置阴影是否显示。
##
## 是否应该显示阴影由 Player / Ball 的 Z 状态决定，
## 本组件只负责应用最终的显示结果。
func set_shadow_visible(visible: bool) -> void:
	shadow_sprite.visible = visible
