extends PlayerState
var hurt_type: Types.HurtType

func enter(attack_direction: Vector2) -> void:
	player.ball_receiver_area.disable()
	if _is_hit_from_front(attack_direction):
		anim.play("heavy_hurt_front")
		
	else :
		anim.play("hurt_back")
	player.player_z_movement.apply_vertical_velocity(4)
	var knockback_direction: Vector2
	knockback_direction = _calculate_knockback_direction(
		attack_direction,
		player.input_component.last_move_direction
	)
	player.player_horizontal_movement.set_horizontal_velocity(
		knockback_direction * 2
	)
	await player.player_z_movement.landed
	player.player_horizontal_movement.set_horizontal_velocity(Vector2.ZERO)
	if _is_hit_from_front(attack_direction):
		anim.play("down_front")
	else :
		anim.play("down_back")
	await player.step_animation_component.animation_finished
	change_state(State.LAND)
	pass
func _is_hit_from_front(attack_direction) -> bool:
	return player.facing_direction != attack_direction

func _calculate_knockback_direction(
	attack_direction: Vector2,
	last_move_direction: Vector2
) -> Vector2:
	var knockback_direction: Vector2

	# 上一次移动方向为斜向
	if (
		last_move_direction.x != 0.0
		and last_move_direction.y != 0.0
	):
		var is_same_horizontal_direction := (
			last_move_direction.x * attack_direction.x > 0.0
		)

		if is_same_horizontal_direction:
			knockback_direction = last_move_direction
		else:
			knockback_direction = -last_move_direction

		return knockback_direction

	# 上一次只进行水平移动
	if last_move_direction.x != 0.0:
		knockback_direction = attack_direction
		return knockback_direction

	# 上一次只进行垂直移动
	if last_move_direction.y != 0.0:
		if attack_direction.x > 0.0:
			knockback_direction = Vector2.UP
		else:
			knockback_direction = Vector2.DOWN

		return knockback_direction
	# 没有上一次移动方向
	knockback_direction = attack_direction
	return knockback_direction
func exit() -> void:
	pass

func process(_delta: float) -> void:
	pass
func physics_tick() -> void:
	pass
func handle_intent(_intent: int, _delta: float) -> void:
	pass
func physics_process(_delta: float) -> void:
	pass
