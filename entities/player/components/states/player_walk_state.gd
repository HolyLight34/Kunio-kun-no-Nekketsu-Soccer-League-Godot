extends PlayerState

var frame_interval: float = 0.2 # 每帧的时间间隔
var n: int = 2 # 模数
var i: int = 0 # 循环周期中的索引

func enter() -> void:
	player.step_animation_component.play(anim_name)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.IDLE:
			print("切换帧：",Engine.get_physics_frames())
			change_state(State.IDLE)
		IntentComponent.Intent.JUMP:
			change_state(State.JUMP)
	pass
func physics_process(_delta: float) -> void:
	pass

func _on_init() -> void:
	pass
