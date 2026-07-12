# hurt_box.gd (通用的受击接收器，人也用它，球也用它)
extends Area2D
class_name HurtBox

# 📢 核心通用信号：只要被锤了，就把这发伤害的完整数据作为信号发出去
signal hit_received(hit_box: HitBox)

func _ready() -> void:
	# 自动把亲儿子的形状涂成半透明的蓝色
	if has_node("CollisionShape2D"):
		$CollisionShape2D.debug_color = Color(0.0, 0.3, 1.0, 0.4)
	pass


func _on_area_entered(area: Area2D) -> void:
	if area is HitBox:
		print("dj")
		## 极其优雅：管你是球还是人，只要是 HitBox 撞了我，我就把整个牌子递给我的主人！
		hit_received.emit(area)
	pass # Replace with function body.
