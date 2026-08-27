extends PlayerState


func enter():
	anim.play(anim_name)
	player.player_z_movement.jump(4)
	player.player_horizontal_movement.halve_y_velocity()
	print(player.player_z_movement.get_z_velocity())
	await player.player_z_movement.landed
	print("当前位置",player.position)
	change_state(State.LAND)
func exit():
	pass
func physics_tick() -> void:
	#print(player.player_horizontal_movement.get_velocity())
	player.player_horizontal_movement.apply_air_steering(player.input_component.move_dir)
	pass

func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass
	
