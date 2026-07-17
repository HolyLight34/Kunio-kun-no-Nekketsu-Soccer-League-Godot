extends PlayerState

var frame_interval: float = 0.2 # 每帧的时间间隔
var n: int = 2 # 模数
var i: int = 0 # 循环周期中的索引


func enter() -> void:
	print(player.facing_direction)
	#i = (i + 1) % n # 循环计数 每次切换帧
	player.animation_player.play("walk")
	#actor.animation_player.seek(i * frame_interval, true)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:
	pass

func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.IDLE:
			change_state(State.IDLE)
	pass
func physics_process(_delta: float) -> void:
	player.movement.apply_input_movement(player.input.move_dir, player.walk_speed)
	pass

func _on_init() -> void:
	pass
