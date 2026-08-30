extends PlayerState

var frame_interval: float = 0.2 # 每帧的时间间隔
var n: int = 2 # 模数
var i: int = 0 # 循环周期中的索引

func enter(_data) -> void:
	anim.play(anim_name)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass
func physics_tick() -> void:
	print(player.player_horizontal_movement.get_horizontal_velocity())
	player.player_horizontal_movement.set_move_velocity(2.375,player.input_component.move_dir)
	pass
func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.IDLE:
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
