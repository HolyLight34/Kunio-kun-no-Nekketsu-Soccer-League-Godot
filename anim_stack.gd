# AnimationStackComponent.gd
class_name AnimationStack
extends Node

signal stack_finished

var target_anim_player: AnimationPlayer

#var _time_stack: Array[float] = []
var _continuous_supplier: Callable
#var _current_anim_name: String = ""
# 🌟 统一存字典栈：[{"name": "idle", "frame": 0}, {"name": "jump", "frame": 21}, ...]
var _frame_stack: Array[Dictionary] = []
@export var debug_mode: bool = true ## 是否开启控制台日志


## 📜 通用日志输出助手（与 VectorStack 保持一致的富文本格式）
func _log_tick_info(anim_name: String,frame_idx: int) -> void:
	if not debug_mode:
		return
		
	var tag_color = "cyan"
	if "jump" in anim_name or "fall" in anim_name:
		tag_color = "yellow"
	elif "land" in anim_name:
		tag_color = "green"
	elif "hurt" in anim_name or "hit" in anim_name:
		tag_color = "red"

	print_rich(
		"[color=%s][动画驱动][/color] 物理帧: [color=gray]%d[/color] | 动画: [color=magenta]%s[/color] | 时间轴: [color=green]%.3fs[/color] | 栈余量: %d" % [
			tag_color,
			Engine.get_physics_frames(),
			anim_name,
			frame_idx,
			_frame_stack.size()
		]
	)


## 🌟 一次性接收 Driver 解包好的动画序列，倒序压栈
func push_sequence(sequence: Array[Dictionary], consume_immediately: bool = false) -> void:
	var copy = sequence.duplicate()
	copy.reverse() # 倒序，以便 pop_back() 按 0->N 顺序弹出
	_frame_stack = copy

	if consume_immediately:
		_on_tick_triggered()

## 🌟 开启持续动画流（支持工厂闭包）
func start_continuous_stream(supplier: Callable, default_anim_name: String = "") -> void:
	_continuous_supplier = supplier


## 🌟 清空动画时间栈（打断动作时调用）
func reset() -> void:
	_frame_stack.clear()
	_continuous_supplier = Callable() # 清空持续流闭包


func _on_tick_triggered() -> void:
	#print(Engine.get_physics_frames())
	# 动态流补货：直接赋值，不复制、不翻转！
	if _frame_stack.is_empty() and _continuous_supplier.is_valid():
		var raw_times: Array[Dictionary] = _continuous_supplier.call()
		raw_times.reverse()
		if raw_times is Array and not raw_times.is_empty():
			_frame_stack.assign(raw_times)

	if _frame_stack.is_empty():
		return
	# 1. 弹出当前 Tick 对应的临时变量字典
	var tick_data: Dictionary = _frame_stack.pop_back()
	
	var anim_name: String = tick_data.get("name", "")
	var frame_idx: int = tick_data.get("frame", 0)
	# 2. 驱动 AnimationPlayer 跳转
	_apply_frame(anim_name, frame_idx)
	#_apply_anim_step(time_step)

	# 🌟 打印日志助手
	_log_tick_info(anim_name,frame_idx)

	# 静态动作收尾 barrier
	if _frame_stack.is_empty() and not _continuous_supplier.is_valid():
		stack_finished.emit()
## 🌟 驱动跳转核心方法
func _apply_frame(anim_name: String, frame_idx: int) -> void:
	if not target_anim_player or anim_name.is_empty():
		return

	if not target_anim_player.has_animation(anim_name):
		return

	var anim_res = target_anim_player.get_animation(anim_name)
	var step_time: float = anim_res.step if anim_res.step > 0.0 else (1.0 / 60.0)

	if target_anim_player.current_animation != anim_name:
		target_anim_player.play(anim_name)

	target_anim_player.seek(frame_idx * step_time, true)
