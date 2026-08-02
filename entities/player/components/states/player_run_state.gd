extends PlayerState

func enter() -> void:
	# 1. 从 InputComponent 获取动态输入闭包
	var move_input_supplier: Callable = player.get_facing_direction_supplier()

	# 2. 调用静态工厂，生成包含位移和动画闭包的字典
	# (支持使用默认参数，也可以显式传自定义速度或帧数组)
	var walk_stream: Dictionary = DynamicStreamFactory.create_run_stream(move_input_supplier)
	player.action_driver_component.execute_dynamic_stream(walk_stream)
	pass


func exit() -> void:
	
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	pass

func handle_intent(intent: int, _delta: float) -> void:
	match intent:
		IntentComponent.Intent.WALK:
		## 用归一化的速度进行点积判断
			if player.input.move_dir.dot(player.facing_direction) < -0.5:
				player.action_driver_component.interrupt_and_clear()
				change_state(State.BRAKE)
	pass
