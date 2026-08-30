extends PlayerState


func enter(data) -> void:
	player.pickup_sensor.monitoring = false
	anim.play("hurt_front")
	var hit_info = data as Types.HitInfo
	player.player_horizontal_movement.set_horizontal_velocity(hit_info.horizontal_velocity)
	player.player_z_movement.apply_vertical_velocity(hit_info.z_velocity)
	await player.player_z_movement.landed
	change_state(State.IDLE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	pass
func physics_process(_delta: float) -> void:
	pass
