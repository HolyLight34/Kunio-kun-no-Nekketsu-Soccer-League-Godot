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
	
func physics_process(_delta: float) -> BallState:
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
