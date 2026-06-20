extends PlayerState

var is_kick: bool # 是否踢
var kick_power: float


func enter(_params: Dictionary = {}) -> void:
	player.vh.play_anim("kick")
	player.velocity = Vector2.ZERO
	player.kick_area.monitoring = true
	await get_tree().physics_frame
	var targets = player.kick_area.get_overlapping_bodies()
	
	for body in targets:
		if body is Ball:
			# 🎯 逮到球了！立刻执行爆射
			body.be_kicked(player.facing_direction, 200.0)
			return # 踢到了就功成身退，不需要再等超时
	
	await player.vh.anim_player.animation_finished
	change_state(State.IDLE) 
	
	#is_kick = true
	#player.pick_up_area.monitoring = false # 关闭拾球检测
	#player.animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	#var targets = player.kick_area.get_overlapping_bodies() # 获取击球框内body
	#for target in targets:
		#if target is Ball:
			#target.kick_power = player.kick_power
			#target.kick_direction = player.facing_direction
			#target.z_height = 5
	pass


func exit() -> void:
	#player.animation_player.animation_finished.disconnect(_on_animation_player_animation_finished)
	#player.pick_up_area.monitoring = true
	pass


func process(_delta: float) -> void:
	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(_intent: int, _delta: float) -> void:
	#match intent:
		#IntentParser.Intent.IDLE:
			#change_state(State.IDLE)
	pass
func _on_animation_player_animation_finished(_a: String) -> void:
	is_kick = false
	pass
