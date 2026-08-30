extends PlayerState

func enter(_data) -> void:
	var hit_data: Types.HitInfo = Types.HitInfo.new()
	hit_data.damage = 2
	hit_data.horizontal_velocity = Vector2(0,2)
	hit_data.z_velocity = 3.5
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


func handle_intent(intent: int, _delta: float) -> void:
	#match intent:
		#IntentComponent.Intent.IDLE:
			#change_state(State.IDLE)
	pass
