class_name StateIdle
extends State


func init() -> void:
	pass


func enter() -> void:
	player.animation_player.play("idle")
	player.velocity = Vector2.ZERO
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> State:
	return nex_state


func process(_delta: float) -> State:
	if player.input_dir != Vector2.ZERO:
		if player.input_dir != Vector2.DOWN and player.input_dir != Vector2.UP:
			player.facing_direction = player.input_dir
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
