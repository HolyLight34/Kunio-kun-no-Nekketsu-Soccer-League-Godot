extends PlayerState


func enter(_data):
	#player.ball_interaction_detector.disable()
	player.ball_receiver_area.disable()
	player.player_horizontal_movement.stop_immediately()
	var z_height: float
	if player.get_z_height() > 0:
		z_height = player.ball.get_z_height()
		print("当前高度", z_height)
	else :
		z_height = 8
	_prepare_hit_box(Types.AttackType.KICK,player.facing_direction,5,8,z_height)
	anim.play(anim_name)
	await anim.animation_finished
	if player.player_z_movement.is_in_air:
		change_state(State.JUMP)
	change_state(State.IDLE)
	pass

func exit() -> void:
	#player.ball_interaction_detector.enable()
	player.hit_box.hit_shape.disabled = true
	player.hit_box.hit_info = null
	pass

func physics_tick() -> void:
	pass
func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
