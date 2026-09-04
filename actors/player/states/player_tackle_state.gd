extends PlayerState


func enter(_data) -> void:
	anim.play(anim_name)
	if player.input_component.move_dir == Vector2.ZERO:
		player.player_horizontal_movement.set_horizontal_velocity(5*player.facing_direction)
	else :
		player.player_horizontal_movement.set_horizontal_velocity(5*player.input_component.move_dir)
	await anim.animation_finished
	change_state(State.LAND)
	pass

func physics_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(x_decel_rate)
	pass
func exit() -> void:

	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	pass
