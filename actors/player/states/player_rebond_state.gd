extends PlayerState


func enter(attack_direction: Vector2) -> void:
	player.fc_logic_clock.pause()
	player.player_horizontal_movement.set_horizontal_velocity(attack_direction*6)

	if _is_hit_from_front(attack_direction):
		step_anim.play(default_anim)
	else:
		step_anim.play("hurt_back")

	pass
func _is_hit_from_front(attack_direction) -> bool:
	return player.facing_direction != attack_direction
func exit() -> void:
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(0.5)
	if step_anim.is_finished():
		request_state(Types.PlayerStateType.IDLE)
