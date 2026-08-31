extends PlayerState


func enter(data) -> void:
	player.pickup_sensor.monitoring = false
	var hit_info := data as Types.HitInfo
	if player.facing_direction != hit_info.attack_direction:
		anim.play("hurt_front")
	else :
		anim.play("hurt_back")
	var knockback_direction := _calculate_knockback_direction(
		hit_info.attack_direction,
		player.input_component.last_move_direction
	)
	player.player_horizontal_movement.set_horizontal_velocity(
		knockback_direction * hit_info.knockback_speed
	)
	player.player_z_movement.apply_vertical_velocity(
		hit_info.z_velocity
	)
	await player.player_z_movement.landed
	player.player_horizontal_movement.set_horizontal_velocity(Vector2.ZERO)
	if player.facing_direction != hit_info.attack_direction:
		anim.play("down_front")
	else :
		anim.play("down_back")
	await player.step_animation_component.animation_finished
	change_state(State.LAND)
func _calculate_knockback_direction(
	attack_direction: Vector2,
	last_move_direction: Vector2
) -> Vector2:
	if last_move_direction.x != 0 and last_move_direction.y != 0:
		return -last_move_direction
	if last_move_direction.x != 0:
		return attack_direction
	if last_move_direction.y != 0:
		return (
			Vector2.UP
			if attack_direction == Vector2.RIGHT
			else Vector2.DOWN
		)
	return attack_direction
		
func exit() -> void:
	player.pickup_sensor.monitoring = false
	pass

func process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	pass
func physics_process(_delta: float) -> void:
	pass
