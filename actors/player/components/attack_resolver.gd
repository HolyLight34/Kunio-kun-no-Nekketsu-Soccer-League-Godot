class_name AttackResolver
extends Node
@export var attacker: Player
# ==============================================================================
# HitBox 命中解析
# ==============================================================================
func resolve_hit(
	hurt_box: HurtBox,
	hit_info: HitInfo
) -> void:
	if hurt_box.target is Player:
		_resolve_player_hit(
			hurt_box,
			hit_info
		)
		return
	if hurt_box.target is Ball:
		print("你好")
		_resolve_ball_hit(
			hurt_box,
			hit_info
		)


# ==============================================================================
# Player → Ball
# ==============================================================================
func _resolve_ball_hit(
	hurt_box: HurtBox,
	hit_info: HitInfo
) -> void:
	if hurt_box.target is not Ball:
		return

	var ball := hurt_box.target as Ball

	match hit_info.attack_type:
		Types.AttackType.KICK:
			_resolve_kick(
				ball,
				hit_info
			)

		Types.AttackType.PASS:
			_resolve_pass(ball)
		Types.AttackType.SLIDE:
			ball._receive_slide_hit(attacker.hit_box)
func _resolve_kick(
	ball: Ball,
	hit_info: HitInfo
) -> void:
	var velocity := Vector3(
		hit_info.attack_direction.x * hit_info.horizontal_speed,
		hit_info.attack_direction.y * hit_info.horizontal_speed,
		hit_info.z_velocity
	)

	ball.receive_kick(
		attacker,
		hit_info.power,
		velocity
	)


# ==============================================================================
# Player → Ball：传球
# ==============================================================================
# PASS 不通过 HitBox / HurtBox。
# PassState 到达真正出球帧时，直接调用这个接口。

func _resolve_pass(ball: Ball) -> void:
	var pass_trajectory_calculator := PassTrajectoryCalculator.new()

	var target_position := (
		attacker.pass_target_detector.get_pass_target_position(ball)
	)

	var pass_velocity := pass_trajectory_calculator.build_pass(
		ball.get_logical_position(),
		target_position
	)

	ball.receive_pass(
		attacker,
		pass_velocity
	)


# ==============================================================================
# Player → Player
# ==============================================================================

func _resolve_player_hit(
	hurt_box: HurtBox,
	hit_info: HitInfo
) -> void:
	if hurt_box.target is not Player:
		return

	var target := hurt_box.target as Player

	if not _can_hit_target(
		target,
		hit_info
	):
		return

	var hurt_data := _create_hurt_data(
		target,
		hit_info
	)

	if hurt_data == null:
		return

	hurt_box.receive_hurt(hurt_data)


# ==============================================================================
# Player 命中条件
# ==============================================================================

func _can_hit_target(
	target: Player,
	hit_info: HitInfo
) -> bool:
	# 不能攻击队友
	if target.team_id == attacker.team_id:
		return false

	match hit_info.attack_type:
		# KICK 只用于踢足球，不直接攻击 Player
		Types.AttackType.KICK:
			return false

		# 铲球只有目标正在跑动时才有效
		Types.AttackType.SLIDE:
			return target.is_running()

	return true


# ==============================================================================
# HurtData 构建
# ==============================================================================

func _create_hurt_data(
	target: Player,
	hit_info: HitInfo
) -> HurtData:
	match hit_info.attack_type:
		Types.AttackType.SLIDE:
			return _create_normal_hurt_data(
				hit_info
			)

		Types.AttackType.ELBOW:
			if attacker.endurance + 8 >= target.endurance:
				return _create_heavy_hurt_data(
					target,
					hit_info
				)

			return _create_normal_hurt_data(
				hit_info
			)

	return null


func _create_heavy_hurt_data(
	target: Player,
	hit_info: HitInfo
) -> HurtData:
	var hurt_data := HurtData.new()

	hurt_data.hurt_type = Types.HurtType.HEAVY
	hurt_data.damage = hit_info.damage

	hurt_data.knockback_direction = _calculate_knockback_direction(
		hit_info.attack_direction,
		target.input_component.last_move_direction
	)

	hurt_data.knockback_speed = hit_info.horizontal_speed
	hurt_data.z_velocity = hit_info.z_velocity

	return hurt_data


func _create_normal_hurt_data(
	hit_info: HitInfo
) -> HurtData:
	var hurt_data := HurtData.new()

	hurt_data.hurt_type = Types.HurtType.NORMAL
	hurt_data.damage = hit_info.damage
	hurt_data.knockback_direction = hit_info.attack_direction
	hurt_data.knockback_speed = 6.0

	return hurt_data


# ==============================================================================
# 击退方向
# ==============================================================================

func _calculate_knockback_direction(
	attack_direction: Vector2,
	last_move_direction: Vector2
) -> Vector2:
	# 上一次移动方向为斜向
	if (
		last_move_direction.x != 0.0
		and last_move_direction.y != 0.0
	):
		var is_same_horizontal_direction := (
			last_move_direction.x * attack_direction.x > 0.0
		)

		if is_same_horizontal_direction:
			return last_move_direction

		return -last_move_direction

	# 上一次只进行水平移动
	if last_move_direction.x != 0.0:
		return attack_direction

	# 上一次只进行垂直移动
	if last_move_direction.y != 0.0:
		if attack_direction.x > 0.0:
			return Vector2.UP

		return Vector2.DOWN

	# 没有上一次移动方向
	return attack_direction
