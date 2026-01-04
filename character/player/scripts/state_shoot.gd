class_name StateShoot
extends State
var is_kick: bool # 是否踢
var data_packet
func init() -> void:
	pass
	
func enter() -> void:
	is_kick = true
	player.area_2d.monitorable = true
	player.animation_player.play("shoot")
	player.animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	player.collision_shape_2d.shape.extents = Vector2(15, 15)
	print("信号已连接")
	player.area_2d.body_entered.connect(_on_area_2d_body_entered)
	data_packet = {
		"power": player.kick_power,
		'direction': player.facing_direction,
		"shooter": player # 甚至可以带上是谁踢的
		}
	pass
	
func exit() -> void:
	player.collision_shape_2d.shape.extents = Vector2(0, 0)
	print("信号已退出")
	player.area_2d.body_entered.disconnect(_on_area_2d_body_entered)
	player.area_2d.monitorable = false
	player.animation_player.animation_finished.disconnect(_on_animation_player_animation_finished)
	pass

func handle_input(_event: InputEvent) -> State:
	return nex_state
	
func process(_delta: float) -> State:
	if !is_kick:
		return idle
	return nex_state
	
func physics_process(_delta: float) -> State:
	return nex_state
	
func _on_area_2d_body_entered(body) -> void:
	print(body)
	if body is Ball:
		player.ball_fired.emit(data_packet)
		print("信号已发出，包含数据：", data_packet)
	pass
func _on_animation_player_animation_finished(_a: String) -> void:
	is_kick = false
	pass
