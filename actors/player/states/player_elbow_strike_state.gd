extends PlayerState

func enter(_data) -> void:
	#player.prepare_strike_hit(2)
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)

func exit() -> void:
	player.close_player_contact_window()
	pass

#func handle_contact(hurt_box: HurtBox) -> void:
	#var target: Player = hurt_box.target
	#if target == player or target.team_id == player.team_id:
		#return

func handle_intent(_intent: int, _delta: float) -> void:
	
	pass
