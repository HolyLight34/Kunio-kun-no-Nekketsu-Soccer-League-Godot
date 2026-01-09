@icon("res://character/state.svg")
class_name State
extends Node
@onready var run: StateRun = %Run
@onready var jump: StateJump = %Jump
@onready var idle: StateIdle = %Idle
@onready var walk: StateWalk = %Walk
@onready var shoot: StateShoot = %Shoot


var player: Player
var nex_state: State = null

func init() -> void: # 状态初始化
	pass
	
func enter() -> void: # 状态进入
	pass
	
func exit() -> void: # 状态退出
	pass

func handle_input(_event: InputEvent) -> State: # 输入事件响应
	return nex_state
	
func process(_delta: float) -> State: # 帧处理
	return nex_state
	
func physics_process(_delta: float) -> State: # 物理帧处理
	return nex_state
	
	
