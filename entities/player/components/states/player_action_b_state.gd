extends PlayerState

func enter() -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			change_state(State.KICK)
		MatchManager.BallPossession.ENEMY_TEAM:
			print("肘击")
			_do_elbow_strike()
		MatchManager.BallPossession.NONE:
			change_state(State.KICK)
	pass


func exit() -> void:
	#player.ball_possession = player.BallPossession.NO_BALL
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass


func _do_elbow_strike() -> void:
	var hit_data: Types.HitInfo = Types.HitInfo.new()
	hit_data.damage = 2
	hit_data.force = 0
	hit_data.direction = player.facing_direction
	player.hit_box.hit_info = hit_data
	await player.action_driver_component.action_finished
	change_state(State.IDLE)
	pass

#
#func _do_kick() -> void:
	#var hit_data: Types.HitInfo = Types.HitInfo.new()
	#hit_data.damage = 5
	#hit_data.force = player.endurance
	#hit_data.direction = player.facing_direction
	#player.hit_box.hit_info = hit_data
	#await player.action_driver_component.action_finished
	#change_state(State.IDLE)
	#pass
