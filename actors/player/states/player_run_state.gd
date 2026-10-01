extends PlayerState

func enter(_data) -> void:
	anim.play(anim_name)
	
	pass
func physics_tick() -> void:
	player.player_horizontal_movement.set_move_velocity(3,Vector2(player.facing_direction.x,player.input_component.move_dir.y))
	pass

func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		PlayerIntentResolver.Intent.WALK:
		## 用归一化的速度进行点积判断
			if player.input_component.move_dir.x+player.facing_direction.x == 0:
				change_state(State.BRAKE)
		PlayerIntentResolver.Intent.JUMP:
			change_state(State.JUMP)
	pass
