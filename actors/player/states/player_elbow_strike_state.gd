extends PlayerState

func enter(_data) -> void:
	player.hit_box.hit_info = _create_hit_info()
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)

func _create_hit_info() -> HitInfo:
	var hit_info := HitInfo.new()
	hit_info.damage = 2.0
	hit_info.attack_direction = player.facing_direction
	hit_info.knockback_speed = 2.0
	hit_info.z_velocity = 4.0
	return hit_info
func exit() -> void:
	player.hit_box.set_deferred("monitorable", false)
	player.hit_box.set_deferred("monitoring", false)


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(intent: int, _delta: float) -> void:
	pass
