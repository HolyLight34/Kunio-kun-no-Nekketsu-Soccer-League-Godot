extends PlayerState

func enter(_params: Dictionary = {}) -> void:
	player.vh.play_anim("pass")
	await player.vh.anim_player.animation_finished
	change_state(State.IDLE) 
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
	#player.movement.apply_movement(Vector2(player.facing_direction.x, 0.5 * input.input_dir.y),player.run_speed)
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass
