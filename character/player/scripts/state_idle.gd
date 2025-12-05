@icon("res://character/state.svg")
class_name StateIdle
extends State
var directional_key: String # 方向键名
var timestamp: int # 时间戳
func init() -> void:
	pass
	
func enter() -> void:
	print("idle状态")
	player.animation_player.play("idle")
	player.velocity = Vector2.ZERO
	pass
	
func exit() -> void:
	pass

func handle_input(event: InputEvent) -> State:
	if event is InputEventMouse:
		return null
	if !event.is_pressed():
		return null
	if event.as_text() != directional_key:
		directional_key = event.as_text()
		timestamp = Time.get_ticks_msec()
		return null
	if Time.get_ticks_msec() - timestamp < 300:
		timestamp = Time.get_ticks_msec()
		return run
	else :
		timestamp = Time.get_ticks_msec()
	return nex_state
	
func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		if player.direction != Vector2.DOWN and player.direction !=Vector2.UP:
			player.facing_direction = player.direction
		return walk
	return nex_state
	
func physics_process(_delta: float) -> State:
	return nex_state
	
	
