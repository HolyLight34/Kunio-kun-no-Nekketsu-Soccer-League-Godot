extends PlayerState


func enter(attack_direction: Vector2) -> void:
	player.player_horizontal_movement.set_horizontal_velocity(attack_direction*6)

	if _is_hit_from_front(attack_direction):
		anim.play(anim_name)
	else:
		anim.play("hurt_back")
	await player.step_animation_component.animation_finished
	request_state(State.IDLE)
	pass
func _is_hit_from_front(attack_direction) -> bool:
	return player.facing_direction != attack_direction
func exit() -> void:
	pass

func logic_tick() -> void:
	player.player_horizontal_movement.decelerate_xy(0.5)
