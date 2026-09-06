extends PlayerState
var hurt_type: Types.HurtType

func enter(data) -> void:
	player.pickup_sensor.monitoring = false
	var hurt_data := data as HurtData
	if hurt_data == null:
		return
	hurt_type = hurt_data.hurt_type
	match hurt_type:
		Types.HurtType.NORMAL:
			normal_hurt(hurt_data)
		Types.HurtType.HEAVY:
			heavy_hurt(hurt_data)
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
	print("数据",hurt_data.knockback_direction * hurt_data.knockback_speed)
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
func physics_tick() -> void:
	if hurt_type == Types.HurtType.NORMAL:
		player.player_horizontal_movement.decelerate_xy(0.5)
func handle_intent(_intent: int, _delta: float) -> void:
	pass
func physics_process(_delta: float) -> void:
	pass
