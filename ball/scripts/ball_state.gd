@icon("res://character/state.svg")
class_name BallState
extends EntityState # 继承自你的通用 State
enum State {
	FREE,
	HOLD,
	SHOT,
} 

@export var state: State # 当前状态设置
# 【核心变量】将通用的 actor 转换为具体的“球员”类型，方便调用球员特有的功能（如血量、速度）
# get: 语法意味着每次使用 player 变量时，都会实时执行后面的转换逻辑
var ball: Ball:
	get:
		return actor as Ball
# PlayerState.gd (状态基类)
