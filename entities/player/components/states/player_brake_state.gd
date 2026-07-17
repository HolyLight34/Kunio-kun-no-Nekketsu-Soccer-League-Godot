extends PlayerState

#var _animation_finished: bool


func enter():
	player.animation_player.play("brake")
	await player.animation_player.animation_finished
	change_state(State.IDLE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
