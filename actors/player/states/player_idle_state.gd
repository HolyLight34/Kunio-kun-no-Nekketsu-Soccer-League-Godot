extends PlayerState

func enter(_data) -> void:
	player.pickup_sensor.monitoring = true
	anim.play(anim_name)
func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass
func physics_tick() -> void:
	player.player_horizontal_movement.apply_ground_friction(x_decel_rate)

func handle_intent(intent: int, _delta: float) -> void:                                                               
	match intent:
		IntentComponent.Intent.RUN:
			change_state(State.RUN)
		IntentComponent.Intent.WALK:
			change_state(State.WALK)
		IntentComponent.Intent.KICK:
			change_state(State.ACTION_B)	
		IntentComponent.Intent.SEND_PASS:
			change_state(State.ACTION_A)
		IntentComponent.Intent.JUMP:
			change_state(State.JUMP)


func physics_process(_delta: float) -> void:
	pass
