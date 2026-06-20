class_name PlayerState
extends EntityState # 继承自你的通用 State

enum State {
	IDLE,
	WALK,
	RUN,
	BRAKE,
	KICK,
	JUMP,
	DRIBBLE_IDLE,
	DRIBBLE_WALK,
	DRIBBLE_RUN,
	DRIBBLE_JUMP,
	DRIBBLE_BRAKE,
	SEND_PASS,
	ELBOW_DIVE,
	BICYCLE_KICK,
	Land,
} 

@export var state: State # 当前状态设置
# 【核心变量】将通用的 actor 转换为具体的“球员”类型，方便调用球员特有的功能（如血量、速度）
# get: 语法意味着每次使用 player 变量时，都会实时执行后面的转换逻辑
var player: Player:
	get:
		return actor as Player
# PlayerState.gd (状态基类)

# 默认所有状态都允许转身
@export var allow_facing_update: bool = true
