extends PlayerState


func enter(_data):
	player.player_horizontal_movement.stop_immediately()
	_prepare_hit_box(Types.AttackType.KICK,player.facing_direction,5,8,8)
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass

func exit() -> void:
	player.hit_box.hit_shape.disabled = true
	player.hit_box.hit_info = null
	pass

func physics_tick() -> void:
	pass
func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
