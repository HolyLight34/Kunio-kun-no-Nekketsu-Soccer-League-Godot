class_name Ball
extends AnimatableBody2D
var states: Array[BallState]
var current_state: BallState:
	get: return states.front()
var previous_state: BallState:
	get: return states[1]
var carrier: Player = null # 足球携带者
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_detection_are: Area2D = $PlayerDetectionAre
@onready var timer: Timer = $Timer

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
	
