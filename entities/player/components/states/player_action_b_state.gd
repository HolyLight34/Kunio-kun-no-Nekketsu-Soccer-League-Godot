extends PlayerState

func enter() -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			change_state(State.KICK)
		MatchManager.BallPossession.ENEMY_TEAM:
			change_state(State.ELBOW_STRIKE)
		MatchManager.BallPossession.NONE:
			change_state(State.KICK)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass
