extends PlayerState

func enter(_params: Dictionary = {}) -> void:
	player.animation_player.play("run")
	#actor.
	pass


func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	#if input.input_dir != Vector2.ZERO:
		## 用归一化的速度进行点积判断
		#if input.input_dir.dot(player.velocity.normalized()) < -0.5:
			#return brake
	player.movement.apply_input_movement(Vector2(player.facing_direction, 0.5 * player.input.move_dir.y),player.run_speed)
	pass


func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.WALK:
		## 用归一化的速度进行点积判断
			if player.input.move_dir.dot(player.velocity.normalized()) < -0.5:
			#return brake
			
				change_state(State.BRAKE)
	pass
