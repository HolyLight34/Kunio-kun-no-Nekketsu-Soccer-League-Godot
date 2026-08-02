extends PlayerState


func enter() -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			print("我运行了一次")
			_do_kick()
		MatchManager.BallPossession.ENEMY_TEAM:
			print("肘击")
			_do_elbow_strike()
		MatchManager.BallPossession.NONE:
			_do_kick()
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
	player.animation_player.play("elbow_strike")
	var hit_data: Types.HitInfo = Types.HitInfo.new()
	hit_data.damage = 2
	hit_data.force = 0
	hit_data.direction = player.facing_direction
	player.hit_box.hit_info = hit_data
	await player.animation_player.animation_finished
	change_state(State.IDLE)
	pass


func _do_kick() -> void:
	player.animation_player.play("kick")
	player.velocity = Vector2.ZERO
	var hit_data: Types.HitInfo = Types.HitInfo.new()
	hit_data.damage = 5
	hit_data.force = player.endurance
	hit_data.direction = player.facing_direction
	#var hit_data: Dictionary = {
		#"damage": 5,
		#"force": 60,
		#"direction": player.facing_direction,
	#}
	player.hit_box.hit_info = hit_data
	await player.animation_player.animation_finished
	change_state(State.IDLE)
	pass
