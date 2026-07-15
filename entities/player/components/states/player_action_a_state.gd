extends PlayerState
func enter(_params: Dictionary = {}) -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			print("我运行了一次") 
			allow_facing_update = false
			_do_pass()
		MatchManager.BallPossession.ENEMY_TEAM:
			print("我撞")
			self.call_deferred("change_state", State.IDLE)
		MatchManager.BallPossession.NONE:
			_do_pass()
			print("对话")
			#self.call_deferred("change_state", State.IDLE)
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


func _do_pass() -> void:
	player.animation_player.play("pass")
	await player.animation_player.animation_finished
	change_state(State.IDLE)
	pass
