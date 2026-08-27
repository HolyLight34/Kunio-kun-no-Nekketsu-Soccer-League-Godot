extends PlayerState


func enter():
	player.player_horizontal_movement.stop_immediately()
	var hit_data: Types.HitInfo = Types.HitInfo.new()
	hit_data.damage = 5
	hit_data.force = player.endurance
	hit_data.direction = player.facing_direction
	player.hit_box.hit_info = hit_data
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
