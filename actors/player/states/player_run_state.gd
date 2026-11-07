extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)

func logic_tick() -> void:
	player.player_horizontal_movement.set_move_velocity(3,Vector2(player.facing_direction.x,player.input_component.move_dir.y))

func exit() -> void:
	
	pass


func handle_intent(intent: int) -> void:
	match intent:
		PlayerIntentResolver.Intent.WALK:
		## 用归一化的速度进行点积判断
			if player.input_component.move_dir.x+player.facing_direction.x == 0:
				request_state(State.BRAKE)
		PlayerIntentResolver.Intent.JUMP:
			request_state(State.JUMP)
		PlayerIntentResolver.Intent.RUN:
			if player.input_component.move_dir.y != 0 and player.input_component.move_dir.x == 0:
				request_state(State.SPECIAL_DRIBBLE)
	pass
