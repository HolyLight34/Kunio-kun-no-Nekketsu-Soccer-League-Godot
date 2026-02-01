class_name StateRun
extends State



func init() -> void:
	can_flip = true
	pass


func enter() -> void:
	player.want_to_run = false
	player.animation_player.play("run")
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> State:
	return nex_state


func process(_delta: float) -> State:
	if player.input_dir != Vector2.ZERO:
		# 用归一化的速度进行点积判断
		if player.input_dir.dot(player.velocity.normalized()) < -0.5:
			return skid
	player.velocity = Vector2(90 * player.facing_direction.x, 20 * player.input_dir.y)

	return nex_state


func physics_process(_delta: float) -> State:
	return nex_state
