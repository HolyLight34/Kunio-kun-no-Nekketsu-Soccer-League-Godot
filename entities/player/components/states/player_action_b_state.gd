extends PlayerState


func enter(_params: Dictionary = {}) -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			print("我运行了一次") 
			allow_facing_update = false
			_do_kick()
		MatchManager.BallPossession.ENEMY_TEAM:
			allow_facing_update = false
			print("肘击")
			_do_elbow_strike()
		MatchManager.BallPossession.NONE:
			allow_facing_update = false
			_do_kick()
	pass


func exit() -> void:
	#player.ball_possession = player.BallPossession.NO_BALL
	pass


func process(_delta: float) -> void:
	pass
func _do_elbow_strike() -> void:
	player.animation_player.play("elbow_strike")
	await player.animation_player.animation_finished
	change_state(State.IDLE) 
	pass
func _do_kick() -> void:
	player.animation_player.play("kick")
	player.velocity = Vector2.ZERO
	player.hit_box.setup(0, player.endurance + 10 , Vector2.RIGHT )
	await player.animation_player.animation_finished
	change_state(State.IDLE) 
	pass

func handle_intent(intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass
