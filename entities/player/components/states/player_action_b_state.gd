extends PlayerState


func enter(_params: Dictionary = {}) -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			print("我运行了一次") 
			allow_facing_update = false
			_do_kick()
		MatchManager.BallPossession.ENEMY_TEAM:
			print("我铲")
			self.call_deferred("change_state", State.IDLE)
		MatchManager.BallPossession.NONE:
			allow_facing_update = false
			_do_kick()
	pass


func exit() -> void:
	#player.ball_possession = player.BallPossession.NO_BALL
	pass


func process(_delta: float) -> void:
	pass
func _do_kick() -> void:
	player.vh.play_anim("kick")
	player.velocity = Vector2.ZERO
	player.kick_area.monitoring = true
	await get_tree().physics_frame
	var targets = player.kick_area.get_overlapping_bodies()
	
	for body in targets:
		if body is Ball:
			# 🎯 逮到球了！立刻执行爆射
			body.be_kicked(player.facing_direction, 200.0)
			 # 踢到了就功成身退，不需要再等超时
	
	await player.vh.anim_player.animation_finished
	change_state(State.IDLE) 
	pass

func handle_intent(intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass
