extends PlayerState


func enter(_data) -> void:
	anim.play(anim_name)
	player.player_horizontal_movement.set_horizontal_velocity(Vector2(4.375,0)*player.facing_direction)
	await anim.animation_finished
	change_state(State.LAND)
	pass

func physics_tick() -> void:
	player.player_horizontal_movement.apply_ground_friction(x_decel_rate)
	pass
func exit() -> void:

	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	pass
