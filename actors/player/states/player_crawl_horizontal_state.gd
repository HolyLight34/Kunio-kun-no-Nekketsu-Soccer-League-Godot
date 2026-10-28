extends PlayerState
@export var is_decelerate: bool = true
func enter(_data) -> void:
	#player.prepare_ball_hit()
	#player.ball_receiver_area.disable()
	anim.play(anim_name)
	await player.step_animation_component.animation_finished
	change_state(State.CRAWL)
	pass

func exit() -> void:
	pass


func physics_tick() -> void:
	if is_decelerate:
		player.player_horizontal_movement.decelerate_x_and_stop_y(x_decel_rate)
	#print(player.player_horizontal_movement.get_horizontal_velocity())
		

func on_set_move_velocity() -> void:
	player.player_horizontal_movement.set_move_velocity(4,player.input_component.move_dir)
	pass
