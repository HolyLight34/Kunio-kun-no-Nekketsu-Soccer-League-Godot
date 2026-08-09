extends PlayerState


func enter() -> void:
	anim.play(anim_name)
	player.speed_vector = Vector2(4.375,0) * player.facing_direction
	await anim.animation_finished
	change_state(State.LAND)
	pass

func physics_tick() -> void:
	apply_state_x_deceleration()
	pass
func exit() -> void:

	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	pass
