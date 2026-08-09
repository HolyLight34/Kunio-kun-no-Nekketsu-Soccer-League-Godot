extends PlayerState

func enter() -> void:
	anim.play(anim_name)
	player.speed_vector = Vector2(3,0) * player.facing_direction
	pass
func physics_tick() -> void:
	pass

func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.WALK:
		## 用归一化的速度进行点积判断
			if player.input_component.move_dir.x+player.facing_direction == 0:
				print(player.input_component.move_dir.x+player.facing_direction)
				change_state(State.BRAKE)
	pass
