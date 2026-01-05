class_name BallStateFreeform
extends BallState
var player_detection_are: Area2D
var is_player: bool = false
func init() -> void:
	player_detection_are = ball.player_detection_are
	player_detection_are.body_entered.connect(on_player_enter)
	#player_detection_are.area_entered.connect(on_are_enter)
	pass
	
func enter() -> void:
	player_detection_are.body_entered.connect(on_player_enter)
	#player_detection_are.area_entered.connect(on_are_enter)
	pass
	
func exit() -> void:
	is_player = false
	player_detection_are.body_entered.disconnect(on_player_enter)
	#player_detection_are.area_entered.disconnect(on_are_enter)
	pass

func handle_input(_event: InputEvent) -> BallState:
	return nex_state
	
func process(_delta: float) -> BallState:
	if is_player:
		return carried
	if ball.player_data != {}:
		return shoot
	return nex_state
	
func physics_process(delta: float) -> BallState:
	# 1. 处理垂直重力逻辑 (Z 轴)
	if ball.z_height > 0 or ball.z_speed != 0:
		ball.z_speed += ball.gravity * delta
		ball.z_height += ball.z_speed * delta
		# 落地判定
		if ball.z_height <= 0:
			ball.z_height = 0
			if abs(ball.z_speed) > 50: # 只有速度够快才反弹，防止无限微弱抖动
				ball.z_speed = -ball.z_speed * ball.bounce_factor
			else:
				ball.z_speed = 0
	ball.sprite_2d.position.y = -ball.z_height
	return nex_state

func on_player_enter(body: Player) -> void:
	ball.carrier = body
	if body is Player:
		is_player = true
	pass
#func on_are_enter(are: Area2D) -> void:
	#print("踢")
	#if are is Area2D:
		#is_kicked = true
	#pass
