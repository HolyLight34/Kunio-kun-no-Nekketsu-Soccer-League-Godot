extends PlayerState

func enter(_data) -> void:
	player.prepare_strike_hit(Types.AttackType.ELBOW,2)
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)

func exit() -> void:
	pass

func handle_contact(hurt_box: HurtBox) -> void:
	var target: Player = hurt_box.target
	if target == player or target.team_id == player.team_id:
		return
func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	
	pass
