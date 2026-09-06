extends PlayerState


func enter(_data) -> void:
	_prepare_hit_box(Types.AttackType.SLIDE,0.0,0.0,0.0)
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
	player.hit_box.hit_shape.disabled = true
	player.hit_box.hit_info = null
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	pass
