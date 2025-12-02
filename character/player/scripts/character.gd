class_name Character
extends CharacterBody2D
var states: Array[State]
var current_state: State:
	get: return states.front()
var previous_state: State:
	get: return states[1]

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
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

func initialize_states() -> void:
	print("ni")
	states = []
	for c in $State.get_children():
		states.append(c)
		print(c)
		c.character = self
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
		current_state.exit()
	states.push_front(new_state)
	current_state.enter()
	states.resize(3)			
	pass
	
	
