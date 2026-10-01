extends PlayerState
var hurt_type: Types.HurtType

func enter(attack_direction: Vector2) -> void:
	player.ball_receiver_area.disable()
	player.player_horizontal_movement.set_horizontal_velocity(attack_direction*6)

	if _is_hit_from_front(attack_direction):
		anim.play("normal_hurt_front")
	else:
		anim.play("hurt_back")
	await player.step_animation_component.animation_finished
	change_state(State.IDLE)
	pass
func _is_hit_from_front(attack_direction) -> bool:
	return player.facing_direction != attack_direction
func exit() -> void:
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
