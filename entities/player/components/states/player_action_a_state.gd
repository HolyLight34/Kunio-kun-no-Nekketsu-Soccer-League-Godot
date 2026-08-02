extends PlayerState

var slide_steps: Array[int] = [0, 3, 3, 3, 2, 1, 0, 0]
var frame_counter: int =0
var current_step_index: int = 0
var is_tackling: bool = false
func enter() -> void:
	match MatchManager.get_possession_for(player):
		MatchManager.BallPossession.MYSELF:
			print("我运行了一次") 
			_do_pass()
		MatchManager.BallPossession.ENEMY_TEAM:
			_start_tackle()
		MatchManager.BallPossession.NONE:
			_do_pass()
			print("对话")
			#self.call_deferred("change_state", State.IDLE)
	pass


func exit() -> void:
	is_tackling = false
	current_step_index = 0
	pass


func process(_delta: float) -> void:
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	if not is_tackling:
		return
		
	frame_counter += 1
	
	# 每 3 帧移动一次
	if frame_counter >= 3:
		frame_counter = 0 
		
		if current_step_index < slide_steps.size():
			var pixels_to_move = slide_steps[current_step_index]
			var step_velocity = player.facing_direction * pixels_to_move
			
			player.global_position += step_velocity
			current_step_index += 1
		else:
			# 🏁 步数走完了，关闭铲球标记，等待动画播完或者直接切回 IDLE
			is_tackling = false
			_finish_tackle()
	pass


func _do_pass() -> void:
	player.animation_player.play("pass")
	await player.animation_player.animation_finished
	change_state(State.IDLE)
	pass
func _start_tackle() -> void:
	is_tackling = true
	var hit_data: Types.HitInfo = Types.HitInfo.new()
	hit_data.damage = 0
	hit_data.force = 0
	hit_data.direction = player.facing_direction
	player.hit_box.hit_info = hit_data
	player.animation_player.play("tackle") # 播放铲球动画
	
	# 在这里顺便开启铲球的 HitBox（红框）
	# player.slide_hit_box.monitoring = true

func _finish_tackle() -> void:
	# 铲球滑行结束后，如果动画还没播完，可以等它播完；或者直接切回站立
	if player.animation_player.is_playing() and player.animation_player.current_animation == "tackle":
		await player.animation_player.animation_finished
	change_state(State.IDLE)
