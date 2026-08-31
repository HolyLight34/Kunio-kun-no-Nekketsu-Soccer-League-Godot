class_name StateMachine
extends Node

@export var initial_state: EntityState

signal tick_reset_requested

var current_state: EntityState
var states: Dictionary = {}
var actor: CharacterBody2D


func _process(delta: float) -> void:
	if current_state:
		current_state.process(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)


func init(actor_node: CharacterBody2D) -> void:
	actor = actor_node

	for child in get_children():
		if child is not EntityState:
			continue

		var state_node := child as EntityState

		state_node.actor = actor_node
		state_node.init()

		if state_node.get("state") != null:
			states[state_node.state] = state_node

		state_node.transition_requested.connect(
			_on_transition_requested
		)

	if initial_state:
		current_state = initial_state
		current_state.enter(null)


func physics_tick() -> void:
	if current_state:
		current_state.physics_tick()


func handle_intent(
	intent: IntentComponent.Intent,
	delta: float
) -> void:
	if current_state:
		current_state.handle_intent(intent, delta)


func change_state(
	target_state_name: Variant,
	data: Variant = null
) -> void:
	_on_transition_requested(
		current_state,
		target_state_name,
		data
	)


func _on_transition_requested(
	from: EntityState,
	to: Variant,
	data: Variant = null
) -> void:
	if from != current_state:
		return

	var target_state := states.get(to) as EntityState
	if not target_state:
		return

	_perform_actual_switch(
		target_state,
		data
	)


func _perform_actual_switch(
	target_state: EntityState,
	data: Variant
) -> void:
	if current_state:
		current_state.exit()

		Log.info(
			Log.Cat.STATE,
			"%s 状态退出: %s 物理帧: %d"
			% [
				actor.name,
				current_state.name,
				Engine.get_physics_frames()
			]
		)

	current_state = target_state

	tick_reset_requested.emit()

	current_state.enter(data)

	Log.info(
		Log.Cat.STATE,
		"%s 状态进入: %s 物理帧: %d"
			% [
				actor.name,
				current_state.name,
				Engine.get_physics_frames()
			]
	)
