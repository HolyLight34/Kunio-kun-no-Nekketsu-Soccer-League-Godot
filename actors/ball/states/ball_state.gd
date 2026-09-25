@icon("res://character/state.svg")
class_name BallState
extends EntityState # 继承自你的通用 State
enum State {
	FREE,
	GRIYND_CARRY,
	SHOT,
	AIR_CONTORL,
	STATIONARY_FLICK,
} 

@export var state: State # 当前状态设置
# 【核心变量】将通用的 actor 转换为具体的“球员”类型，方便调用球员特有的功能（如血量、速度）
# get: 语法意味着每次使用 player 变量时，都会实时执行后面的转换逻辑
var ball: Ball:
	get:
		return actor as Ball
# PlayerState.gd (状态基类)
func _prepare_hit_box(
	attack_type: Types.AttackType,
	attack_direction: Vector2,
	damage: float,
	horizontal_speed: float,
	z_velocity: float
) -> void:
	var hit_info := HitInfo.new()
	hit_info.attack_type = attack_type
	hit_info.damage = damage
	hit_info.attack_direction = attack_direction
	hit_info.horizontal_speed = horizontal_speed
	hit_info.z_velocity = z_velocity
	ball.hit_box.hit_info = hit_info
