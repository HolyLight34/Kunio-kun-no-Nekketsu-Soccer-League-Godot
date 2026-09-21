extends PlayerState

func enter(_data) -> void:
	player.ball_interaction_detector.disable()
	_prepare_hit_box(Types.AttackType.PASS,Vector2.ZERO,0,0,0)
	anim.play(anim_name)
	await anim.animation_finished
	change_state(State.IDLE)
	pass

func exit() -> void:
	player.ball_interaction_detector.enable()
	player.hit_box.hit_shape.disabled = true
	player.hit_box.hit_info = null
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(intent: int, _delta: float) -> void:
	
	pass
