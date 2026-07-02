extends PlayerState


func enter(_params: Dictionary = {}) -> void:
	match player.ball_possession:
		player.BallPossession.HAS_BALL:
			_do_pass()
		player.BallPossession.ENEMY_HAS_BALL:
			print("我铲")
		player.BallPossession.NO_BALL:
			_do_pass()
			print("对话")
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass


func _do_pass() -> void:
	player.vh.play_anim("pass")
	await player.vh.anim_player.animation_finished
	change_state(State.IDLE)
	pass
