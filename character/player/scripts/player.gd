class_name Player
extends CharacterBody2D
var states: Array[State]
signal ball_fired(data: Dictionary)
var current_state: State: # 当前状态
	get: return states.front()
var previous_state: State: # 上一次状态
	get: return states[1]
var facing_direction: Vector2 = Vector2.RIGHT # 面朝方向
var direction: Vector2 = Vector2.ZERO # 输入方向
@export var kick_power: float
# 键映射向量
var key_to_vector: Dictionary = {
	"A": Vector2.LEFT,
	"D": Vector2.RIGHT,
	"W": Vector2.UP,
	"S": Vector2.DOWN
}
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var area_2d: Area2D = $Area2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
func _ready() -> void:
	current_state = %Idle
	initialize_states()
	pass
func _unhandled_input(event: InputEvent) -> void:
	change_state(current_state.handle_input(event))
	pass	
func _process(delta: float) -> void:
	update_direction()
	change_state(current_state.process(delta))
	pass
	
func _physics_process(delta: float) -> void:
	change_state(current_state.physics_process(delta))
	move_and_slide()
	pass

func initialize_states() -> void:
	states = []
	for c in $States.get_children():
		states.append(c)
		c.player = self
	if states.size() == 0:
		return
	for state in states:
		state.init()	
	change_state(current_state)
	pass
	
func change_state(new_state: State) -> void:
	if new_state == null:
		return
	elif new_state == current_state:
		return
	if current_state:
		print("我推出了")
		current_state.exit()
	states.push_front(new_state)
	current_state.enter()
	states.resize(3)			
	pass
	
func update_direction() -> void: # 通过输入更新方向
	direction = Input.get_vector("left","right","up","down")
	if !current_state is StateRun:
		if direction == Vector2.LEFT:
			$Sprite2D.flip_h = true
		elif direction == Vector2.RIGHT:
			$Sprite2D.flip_h = false
	pass
