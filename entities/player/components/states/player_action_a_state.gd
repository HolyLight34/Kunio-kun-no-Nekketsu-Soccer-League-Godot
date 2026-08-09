extends PlayerState

var is_tackling: bool = false
func enter() -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			change_state(State.PASS)
		MatchManager.BallPossession.ENEMY_TEAM:
			change_state(State.TACKLE)
		MatchManager.BallPossession.NONE:
			change_state(State.PASS)
	pass


func exit() -> void:
	is_tackling = false
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:

	pass


#func _do_pass() -> void:
	#change_state(State.IDLE)
	#pass
func _start_tackle() -> void:
	is_tackling = true
	var hit_data: Types.HitInfo = Types.HitInfo.new()
	hit_data.damage = 0
	hit_data.force = 0
	hit_data.direction = player.facing_direction
	player.hit_box.hit_info = hit_data
	player.animation_player.play("tackle") # 播放铲球动画
	

func _finish_tackle() -> void:
	# 铲球滑行结束后，如果动画还没播完，可以等它播完；或者直接切回站立
	if player.animation_player.is_playing() and player.animation_player.current_animation == "tackle":
		await player.animation_player.animation_finished
	change_state(State.IDLE)
