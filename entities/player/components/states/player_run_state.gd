extends PlayerState

func enter() -> void:
	
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
			if player.input.move_dir.dot(player.facing_direction) < -0.5:
				player.action_driver_component.interrupt_and_clear()
				change_state(State.BRAKE)
	pass
