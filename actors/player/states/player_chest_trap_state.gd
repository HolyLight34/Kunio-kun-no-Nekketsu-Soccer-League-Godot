extends PlayerState

func enter(_data) -> void:
	player.player_horizontal_movement.stop_immediately()
	anim.play(anim_name)
	await player.step_animation_component.animation_finished
	change_state(State.IDLE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass
