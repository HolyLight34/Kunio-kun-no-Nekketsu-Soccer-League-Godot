@icon("res://character/state.svg")
class_name StateWalk
extends State
var walk_frame: int = 0 # 动画起始帧
var walk_frame_count: int = 2 # 腿部动作的帧数
var frame_duration: float = 0.2  # 每帧持续时间
func init() -> void:
	pass
	
func enter() -> void:
	walk_frame = (walk_frame + 1) % walk_frame_count  # 循环计数 每次切换帧
	player.animation_player.play("walk")
	player.animation_player.seek(walk_frame * frame_duration, true)
	pass
	
func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> State:
	return nex_state
	
func process(_delta: float) -> State:
	player.animation_player.play("walk")
	player.velocity = player.direction * 30	
	if player.direction == Vector2.ZERO:
		return idle
	return nex_state
	
func physics_process(_delta: float) -> State:
	return nex_state
	
	
