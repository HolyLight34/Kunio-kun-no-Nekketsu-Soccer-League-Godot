# height_component.gd
extends Node
class_name HeightComponent

@export var sprite: Node2D

# 🎯 经过严格换算得出的物理常数
var gravity: float = 213.0  # 对应 60 帧环境下的重力加速度（像素/秒²）
var height: float = 68.0    # 初始高度
var vertical_velocity: float = 0.0 # 初始向下速度（0）
var _frame_count: int = 0 # 用来记录帧数
func _physics_process(delta: float) -> void:
	if height > 0.0:
		# 1. 正常的 60Hz 物理更新
		vertical_velocity -= gravity * delta
		height += vertical_velocity * delta
		#print(height)
		# 落地判定
		if height <= 0.0:
			height = 0.0
			vertical_velocity = 0.0
			
		# 2. 完美的像素对齐渲染
		if sprite != null:
			sprite.position.y = -floor(height)
		_frame_count += 1
		if _frame_count >= 3:
			_frame_count = 0 # 重置计数
			# floor(height) 可以去掉小数，只打印整数像素
			print(sprite.position.y)
