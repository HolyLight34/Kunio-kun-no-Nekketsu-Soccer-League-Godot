# global_enums.gd
class_name Types  # 🌟 这一行最重要！赋予它全项目通用的类名
extends RefCounted
## 1. 🎯 定义你梳理出的 4 种神级核心动作类型
#enum AttackType {
	#PUNCH_KICK,    # 拳脚打斗（普通搏击）
	#SLIDE_TACKLE,  # 铲球/滑铲（抢断，或人对球的拦截）
	#BALL_KICK,     # 踢球动作
	#BALL_STRIKE    # 飞球撞击（飞行的球作为子弹撞人）
#}

# 2. 📦 定义你的“神圣打击情报包”（不再使用字典！）
class HitInfo:
	var damage: float = 0.0
	var horizontal_velocity: Vector2 = Vector2.ZERO
	var z_velocity: float = 0.0
	var power: float = 0.0
	#var type: Types.AttackType = Types.AttackType.PUNCH_KICK
	
	# (未来如果有暴击、属性攻击等，直接在下面这里加变量就行，全项目瞬间同步！)
