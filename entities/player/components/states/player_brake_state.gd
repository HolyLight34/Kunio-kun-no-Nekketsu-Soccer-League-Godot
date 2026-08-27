extends PlayerState


func enter():
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass
func physics_tick() -> void:
	player.player_horizontal_movement.apply_ground_friction(x_decel_rate)
func exit() -> void:
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
