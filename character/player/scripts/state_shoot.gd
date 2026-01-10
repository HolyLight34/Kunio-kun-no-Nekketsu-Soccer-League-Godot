class_name StateShoot
extends State

var is_kick: bool # 是否踢


func init() -> void:
	pass


func enter() -> void:
	player.velocity = Vector2.ZERO
	is_kick = true
	player.pick_up_area.monitoring = false # 关闭拾球检测
	player.animation_player.play("shoot")
	player.animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	var targets = player.kick_area.get_overlapping_bodies() # 获取击球框内body
	for target in targets:
		if target is Ball:
			target.kick_power = player.kick_power
			target.kick_direction = player.facing_direction
			target.z_height = 5
	pass


func exit() -> void:
	player.animation_player.animation_finished.disconnect(_on_animation_player_animation_finished)
	player.pick_up_area.monitoring = true
	pass


func handle_input(_event: InputEvent) -> State:
	return nex_state


func process(_delta: float) -> State:
	if !is_kick:
		return idle
	return nex_state


func physics_process(_delta: float) -> State:
	return nex_state


func _on_animation_player_animation_finished(_a: String) -> void:
	is_kick = false
	pass
