class_name StateSkid
extends State
var _animation_finished: bool
func init() -> void:
	can_flip = false
	pass


func enter() -> void:
	_animation_finished = false
	player.animation_player.play("brake")
	player.animation_player.animation_finished.connect(_on_animation_finished) # 连接动画完成方法
	pass


func exit() -> void:
	player.animation_player.animation_finished.disconnect(_on_animation_finished)
	pass


func handle_input(_event: InputEvent) -> State:
	return nex_state


func process(_delta: float) -> State:
	player.velocity = player.facing_direction * 30
	if _animation_finished:
		return idle
	return nex_state

func physics_process(_delta: float) -> State:
	return nex_state
	
func _on_animation_finished(_a: String) -> void:
	_animation_finished = true
	pass
