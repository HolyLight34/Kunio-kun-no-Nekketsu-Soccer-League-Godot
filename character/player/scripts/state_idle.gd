class_name StateIdle
extends State


func init() -> void:
	can_flip = true
	pass


func enter() -> void:
	player.velocity = Vector2.ZERO
	player.animation_player.play("idle")
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> State:
	return nex_state


func process(_delta: float) -> State:
	if player.input_dir != Vector2.ZERO:
		return walk
	if player.want_to_run:
		return run
	if player.want_to_shoot:
		return shoot
	if player.want_to_pass:
		return passing
	return nex_state


func physics_process(_delta: float) -> State:
	return nex_state
