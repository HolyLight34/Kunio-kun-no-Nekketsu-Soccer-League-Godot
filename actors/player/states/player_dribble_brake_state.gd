extends PlayerState


func enter(_data):
	player.player_horizontal_movement.stop_immediately()
	_prepare_hit_box(Types.AttackType.KICK,5,2,4)
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass

func exit() -> void:
	player.hit_box.hit_shape.disabled = true
	player.hit_box.hit_info = null
	pass
func handle_contact(hurt_box: HurtBox) -> void:
	if hurt_box.target is Player:
		return
	if hurt_box.target is Ball:
		var target = hurt_box.target as Ball
		target.receive_kick(player.hit_box.hit_info)	
func physics_tick() -> void:
	pass
func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
