class_name Ball
extends AnimatableBody2D
var states: Array[BallState]
var current_state: BallState:
	get: return states.front()
var previous_state: BallState:
	get: return states[1]
var kick_power: float # 踢力大小
var kick_direction: Vector2 # 踢力方向
var carrier: Player = null # 足球携带者
var z_height: float = 0.0           # 当前高度 (Z)
var z_speed: float = 0.0            # 垂直速度
@export var gravity: float = -800.0         # 重力加速度 (负值向上)
@export var bounce_factor: float = 0.6      # 弹力系数 (0.6 表示每次落地能量损耗 40%)
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow

func _ready() -> void:
	current_state = %Freeform
	initialize_states()
	pass
func _unhandled_input(event: InputEvent) -> void:
	change_state(current_state.handle_input(event))
	pass	
func _process(delta: float) -> void:
	change_state(current_state.process(delta))
	pass
	
func _physics_process(delta: float) -> void:
	change_state(current_state.physics_process(delta))
	pass

func initialize_states() -> void: # 状态初始化
	states = []
	for c in $States.get_children():
		states.append(c)
		c.ball = self
	if states.size() == 0:
		return
	for state in states:
		state.init()
	change_state(current_state)
	pass
	
func change_state(new_state: BallState) -> void: # 切换状态
	if new_state == null:
		return
	elif new_state == current_state:
		return
	if current_state:
		current_state.exit()
	states.push_front(new_state)
	current_state.enter()
	states.resize(3)
	pass
