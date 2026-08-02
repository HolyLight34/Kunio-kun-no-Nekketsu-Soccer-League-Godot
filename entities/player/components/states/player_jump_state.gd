extends PlayerState


func enter():
	player.action_driver_component.execute_action(action_data)
	await player.action_driver_component.landed
	change_state(State.LAND)
func exit():
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass
	
