class_name BallStateCarried
extends BallState
var carry_offset: Vector2
var frame_interval: float = 0.1 # 每帧的时间间隔
var n: int = 4 # 模数
var i: int = 0 # 循环周期中的索引
func init() -> void:
	pass
	
func enter() -> void:
	carry_offset = Vector2(11,-7)
	pass
	
func exit() -> void:
	pass
func handle_input(event: InputEvent) -> BallState:
	if !event.is_pressed():
		return null
	if event.as_text() == "D":
		if ball.timer.is_stopped():
			ball.timer.start()
			ball.animation_player.play("scroll")
			ball.animation_player.seek((n - 1 - i % n) * frame_interval, true)
			ball.animation_player.pause()
			i += 1
	else :
		if ball.timer.is_stopped():
			ball.timer.start()
			ball.animation_player.play("scroll")
			ball.animation_player.seek(i % n * frame_interval, true)
			ball.animation_player.pause()
			i += 1
	return nex_state
	
func process(_delta: float) -> BallState:
	ball.position = ball.carrier.position + carry_offset * Vector2(ball.carrier.facing_direction.x,1)
	return nex_state
	
func physics_process(_delta: float) -> BallState:
	return nex_state
