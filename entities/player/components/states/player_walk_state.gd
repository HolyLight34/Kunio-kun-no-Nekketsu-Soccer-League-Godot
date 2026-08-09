extends PlayerState

var frame_interval: float = 0.2 # 每帧的时间间隔
var n: int = 2 # 模数
var i: int = 0 # 循环周期中的索引

func enter() -> void:
	anim.play(anim_name)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass
func physics_tick() -> void:
	if player.input_component.move_dir != Vector2.ZERO:
		player.speed_vector = player.calculate_walk_velocity(player.input_component.move_dir)
	else :
		apply_state_x_deceleration()
	pass
func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.IDLE:
			if player.speed_vector == Vector2.ZERO:
				change_state(State.IDLE)
		IntentComponent.Intent.JUMP:
			change_state(State.JUMP)
		IntentComponent.Intent.RUN:
			change_state(State.RUN)
	pass
func physics_process(_delta: float) -> void:
	pass

func _on_init() -> void:
	pass
