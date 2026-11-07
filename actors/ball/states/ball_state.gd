@icon("res://character/state.svg")
class_name BallState
extends EntityState # 继承自你的通用 State
enum State {
	FREE,
	GROUND_CARRY,
	SHOT,
	AIR_CONTROL,
	JUGGLE,
	BICYCLE_KICK_FLICK,
	STOMPED,
} 
@export var ball_state_id: State
func get_state_id() -> int:
	return ball_state_id

# 【核心变量】将通用的 actor 转换为具体的“球员”类型，方便调用球员特有的功能（如血量、速度）
# get: 语法意味着每次使用 player 变量时，都会实时执行后面的转换逻辑
var ball: Ball:
	get:
		return actor as Ball
