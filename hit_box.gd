# hit_box.gd
class_name HitBox
extends Area2D
signal hit_landed
# 📦 击中情报包（Info 比 Data 更有“传输”和“容纳万物”的感觉）
@export var attacker: CharacterBody2D
var hit_info: Dictionary[StringName, Variant] = {
	"damage": 0.0,
	"force": 0.0,
	"direction": Vector2.ZERO
}

# 名字依然叫 setup，传入我们全新的 info 字典
func setup(info: Dictionary) -> void:
	hit_info["damage"]    = float(info.get("damage", 0.0))
	hit_info["force"]     = float(info.get("force", 0.0))
	hit_info["direction"] = info.get("direction", Vector2.ZERO) as Vector2
