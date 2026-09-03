extends PlayerState


func enter(data) -> void:
	player.pickup_sensor.monitoring = false
	var hurt_data = data as HurtData
	match hurt_data.hurt_type:
		Types.HurtType.NORMAL:
			normal_hurt(hurt_data)
			pass
		Types.HurtType.HEAVY:
			heavy_hurt(hurt_data)
			pass
	
func normal_hurt(hurt_data: HurtData):
	if player.facing_direction != hurt_data.knockback_direction:
		anim.play("normal_hurt_front")
	else :
		anim.play("hurt_back")
	player.player_horizontal_movement.set_horizontal_velocity(
		hurt_data.knockback_direction * hurt_data.knockback_speed
	)
	await player.step_animation_component.animation_finished
	change_state(State.IDLE)
	pass
func heavy_hurt(hurt_data: HurtData):
	if player.facing_direction != hurt_data.knockback_direction:
		anim.play("heavy_hurt_front")
	else :
		anim.play("hurt_back")
	player.player_horizontal_movement.set_horizontal_velocity(
		hurt_data.knockback_direction * hurt_data.knockback_speed
	)
	player.player_z_movement.apply_vertical_velocity(
		hurt_data.z_velocity
	)
	await player.player_z_movement.landed
	player.player_horizontal_movement.set_horizontal_velocity(Vector2.ZERO)
	if player.facing_direction != hurt_data.knockback_direction:
		anim.play("down_front")
	else :
		anim.play("down_back")
	await player.step_animation_component.animation_finished
	change_state(State.LAND)
	pass

func exit() -> void:
	player.pickup_sensor.monitoring = false
	pass

func process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	pass
func physics_process(_delta: float) -> void:
	pass
