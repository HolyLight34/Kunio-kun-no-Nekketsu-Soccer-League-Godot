extends PlayerState

func enter(_data) -> void:
	player.step_animation_component.play(anim_name)
	await anim.animation_finished
	print("当前位置",player.position)
	change_state(State.IDLE)
	pass

func physics_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(x_decel_rate)
	pass
func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass


func handle_intent(intent: int, _delta: float) -> void:
	pass
