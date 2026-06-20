extends PlayerState

#var _animation_finished: bool


func enter(_params: Dictionary = {}):
	player.vh.play_anim("brake")
	await player.vh.anim_player.animation_finished
	change_state(State.DRIBBLE_IDLE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
