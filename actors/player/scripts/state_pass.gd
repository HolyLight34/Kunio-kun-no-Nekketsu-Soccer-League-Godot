class_name PlayerStatePass
extends State
var is_kick: bool # 是否踢
func init() -> void:
	can_flip = false
	pass


func enter() -> void:
	player.velocity = Vector2.ZERO
	is_kick = true
	player.pick_up_area.monitoring = false # 关闭拾球检测
	player.animation_player.play('pass')
	player.animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	var teammates = get_tree().get_nodes_in_group("players")
	var totarger: Vector2
	for p: Player in teammates:
		if p == player:
			continue # 排除自己
		totarger = p.position
	var targets = player.kick_area.get_overlapping_bodies() # 获取击球框内body
	for target in targets:
		if target is Ball:
			target.landing_point = totarger
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
