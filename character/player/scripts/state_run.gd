class_name StateRun
extends State
var _animation_finished: bool
var is_braking: bool = false
func init() -> void:
	pass
	
func enter() -> void:
	_animation_finished = false
	player.animation_player.animation_finished.connect(_on_animation_finished) # 连接动画完成方法
	player.animation_player.play("run")
	pass
	
func exit() -> void:
	player.animation_player.animation_finished.disconnect(_on_animation_finished)
	is_braking = false
	pass

func handle_input(event: InputEvent) -> State:
	if !event.is_pressed():
		return null
	if player.key_to_vector[event.as_text()] + player.facing_direction == Vector2.ZERO:
		player.animation_player.play("brake")
		is_braking = true
		player.velocity = player.facing_direction * 50
	return nex_state
	
func process(_delta: float) -> State:
	if !is_braking:
		if player.direction.y != 0:
			player.velocity = player.facing_direction * 60 + player.direction * 30
		else :
			player.velocity = player.facing_direction * 60
	if _animation_finished:
			return idle
	return nex_state
	
func physics_process(_delta: float) -> State:
	return nex_state
	
func _on_animation_finished(_a: String) -> void:
	_animation_finished = true
	pass	
