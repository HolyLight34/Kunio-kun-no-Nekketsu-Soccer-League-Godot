extends PlayerState

func enter(_data) -> void:
	_prepare_hit_box(Types.AttackType.ELBOW,2.0,2.0,4.0)
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)

func exit() -> void:
	player.hit_box.hit_shape.disabled = true
	player.hit_box.hit_info = null

func handle_contact(hurt_box: HurtBox) -> void:
	var target: Player = hurt_box.target
	if target == player or target.team_id == player.team_id:
		return
	var hurt_data: HurtData 
	hurt_data = player._create_normal_hurt_data(-player.facing_direction)
	if player.endurance + 8 < target.endurance:
		change_state(State.HURT,hurt_data)
func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(intent: int, _delta: float) -> void:
	
	pass
