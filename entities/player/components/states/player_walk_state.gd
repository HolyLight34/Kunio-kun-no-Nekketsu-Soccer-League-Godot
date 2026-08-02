extends PlayerState

var frame_interval: float = 0.2 # 每帧的时间间隔
var n: int = 2 # 模数
var i: int = 0 # 循环周期中的索引


func enter() -> void:
	# 1. 从 InputComponent 获取动态输入闭包
	var move_input_supplier: Callable = player.input.get_move_dir_supplier()

	# 2. 调用静态工厂，生成包含位移和动画闭包的字典
	# (支持使用默认参数，也可以显式传自定义速度或帧数组)
	var walk_stream: Dictionary = DynamicStreamFactory.create_walk_stream(move_input_supplier)
	player.action_driver_component.execute_dynamic_stream(walk_stream)
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
	pass

func _on_init() -> void:
	pass
