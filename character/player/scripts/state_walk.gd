class_name StateWalk
extends State

var frame_interval: float = 0.2 # 每帧的时间间隔
var n: int = 2 # 模数
var i: int = 0 # 循环周期中的索引


func init() -> void:
	can_flip = true
	pass


func enter() -> void:
	i = (i + 1) % n # 循环计数 每次切换帧
	player.animation_player.play("walk")
	player.animation_player.seek(i * frame_interval, true)
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> State:
	return nex_state


func process(_delta: float) -> State:
	player.velocity = player.input_dir * 30
	if player.input_dir == Vector2.ZERO:
		return idle
	return nex_state


func physics_process(_delta: float) -> State:
	return nex_state
