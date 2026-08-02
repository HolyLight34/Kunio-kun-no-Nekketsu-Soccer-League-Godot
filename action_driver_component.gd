# ActionDriverComponent.gd
class_name ActionDriverComponent
extends Node

## 📢 对外暴露的统一信号
signal action_finished               ## 当前动作完全结束
signal landed()  ## 角色刚刚落回地面
## 🌟 方式 B：通过 @export 属性 + Setter 自动下发
@export var target_body: CharacterBody2D:
	set(value):
		target_body = value
		if is_node_ready() and vector_stack:
			vector_stack.target_body = value
@export var visual_pivot: Node2D:
	set(value):
		visual_pivot = value
		if is_node_ready() and vector_stack:
			vector_stack.visual_pivot = value
@export var target_anim_player: AnimationPlayer:
	set(value):
		target_anim_player = value
		if is_node_ready() and anim_stack:
			anim_stack.target_anim_player = value

# 标记两个子组件是否都在当前动作中完成
var _vector_done: bool = false
var _anim_done: bool = false
# -------------------------------------------------------------
# 🎨 编辑器可配置动画参数
# -------------------------------------------------------------
@export_group("Fall Animation Settings")
## 默认下落动画名称
@export var default_fall_anim: String = "fall"

## 下落动画的起始帧（从 1 开始计：填 1 代表第 1 帧，填 2 代表第 2 帧）
@export_range(1, 100, 1) var fall_start_frame: int = 2

## 下落动画的结束帧（从 1 开始计：填 4 代表第 4 帧）
@export_range(1, 100, 1) var fall_end_frame: int = 4
# 标记当前是否处于无限动态流模式（动态流不触发完成屏障）
var _is_dynamic_stream: bool = false

@onready var vector_stack: VectorStack = $VectorStack
@onready var anim_stack: AnimationStack = $AnimStack
@onready var ticker: Ticker = $Ticker
# 🌟 专用记录：记住上一次真正播放过的动画名与帧号
var _last_played_anim: String = "idle"  # 默认初始化为 idle
var _last_played_frame: int = 0
func _ready() -> void:
	# 🌟 必须在 _ready 里把 @export 进来的节点显式下发给子组件！
	if vector_stack:
		vector_stack.target_body = target_body
		vector_stack.visual_pivot = visual_pivot
	if anim_stack:
		anim_stack.target_anim_player = target_anim_player
## 1. 静态动作入口
func execute_action(action_data: TickActionData, input_dir: Vector2 = Vector2.ZERO) -> void:
	if not action_data:
		return

	interrupt_and_clear()
	_is_dynamic_stream = false

	var steps: Array[Vector3] = []
	var frames: Array[int] = []

	# 🌟 直接从数据包获取是否允许翻转
	var can_flip = action_data.allow_facing_flip
	# 🌟 1. 处理视觉动画镜像（贴图翻转）
	_apply_visual_facing(input_dir, can_flip)
	var anim_sequence: Array[Dictionary] = [] # 🌟 用 Dictionary 临时变量数组！
	var new_anim: String = action_data.anim_name if not action_data.anim_name.is_empty() else _last_played_anim
	for step in action_data.ticks:
		var final_step = _apply_facing(step.move_step, input_dir, can_flip)
		steps.append(final_step)
		if step.anim_frame == -1:
			# -1 前摇继承：打包旧动画名与旧帧号
			anim_sequence.append({"name": _last_played_anim, "frame": _last_played_frame})
		else:
			# 正式动作帧：打包新动画名与新帧号
			anim_sequence.append({"name": new_anim, "frame": step.anim_frame})
			# 更新记忆
			_last_played_anim = new_anim
			_last_played_frame = step.anim_frame

	vector_stack.push_sequence(steps)
	anim_stack.push_sequence(anim_sequence)

	ticker.reset_tick_and_trigger()
## 监听：物理开始下落 -> 指挥动画播放下落流
## 🌟 当 VectorStack 抛出下落总步数 required_ticks 时：
# -------------------------------------------------------------
# 📢 下落信号响应函数
# -------------------------------------------------------------
func _on_vector_fall_started(_peak_height: int, required_ticks: int) -> void:
	if not anim_stack:
		return

	# 1. 人类视角 (1~N 帧) 转换为 代码索引视角 (0~N-1 索引)
	var start_idx: int = max(0, fall_start_frame - 1)
	var end_idx: int = max(start_idx, fall_end_frame - 1)
	
	# 2. 计算参与循环的帧数区间 (比如第 2~4 帧，区间大小就是 3 帧)
	var loop_count: int = (end_idx - start_idx) + 1

	# 3. 根据所需物理 Tick 数生成帧序号序列
	var fall_frames: Array[Dictionary] = []
	for i in range(required_ticks):
		# 算法：起始偏移 + 区间取余
		var frame_index: int = start_idx + (i % loop_count)
		fall_frames.append({"name": default_fall_anim, "frame": frame_index})

	# 4. 压入动画栈
	anim_stack.push_sequence(fall_frames, true)
## 监听：物理落地 -> 指挥动画清空下落流
func _on_vector_landed() -> void:
	if anim_stack:
		anim_stack.reset()
	landed.emit()
	# （可选）如果有落地硬直/落地缓冲动画，可以在这里压入或抛给状态机

## 2. 🌟 动态动作入口（走路、跑步、自由落体等无限/动态流）
## 配合 MotionStreamFactory 和 AnimStreamFactory 使用
## 🌟 执行动态流（直接接收 DynamicStreamFactory 产出的流字典）
func execute_dynamic_stream(stream_data: Dictionary) -> void:
	# 1. 安全校验：确保传入的字典非空且包含必要的闭包
	if stream_data.is_empty():
		return

	# 2. 打断旧动作并标记状态
	interrupt_and_clear()
	_is_dynamic_stream = true

	# 3. 提取闭包并注入底层组件
	var vector_supplier: Callable = stream_data.get("vector_supplier", Callable())
	var anim_supplier: Callable = stream_data.get("anim_supplier", Callable())

	if vector_stack and vector_supplier.is_valid():
		vector_stack.start_continuous_stream(vector_supplier)

	if anim_stack and anim_supplier.is_valid():
		anim_stack.start_continuous_stream(anim_supplier)

	# 4. 重置并触发 Tick 脉冲
	ticker.reset_tick_and_trigger()

## 3. 🌟 核心：彻底打断并清空当前底层所有栈和完成状态
func interrupt_and_clear() -> void:
	# 重置同步屏障标志位（极其关键！）
	_vector_done = false
	_anim_done = false
	_is_dynamic_stream = false

	if vector_stack:
		vector_stack.reset()
	if anim_stack:
		anim_stack.reset()


## 🌟 辅助函数：增加 can_flip 阀门
func _apply_facing(step: Vector3, input_dir: Vector2, can_flip: bool) -> Vector3:
	# 如果动作禁止翻转，直接返回原始位移
	if not can_flip:
		return step

	var result = step
	if input_dir.x < 0:
		result.x = -result.x
	return result
## 🌟 新增：处理动画/贴图的视觉节点 (Pivot) 镜像翻转
func _apply_visual_facing(input_dir: Vector2, can_flip: bool) -> void:
	# 没有配置 visual_pivot 或明确禁止翻转时，直接返回
	if not visual_pivot or not can_flip:
		return
		
	# 只要按了左键 (input_dir.x < 0)，视觉镜像翻转；按了右键，恢复正向
	if input_dir.x < 0:
		visual_pivot.scale.x = -abs(visual_pivot.scale.x)
	elif input_dir.x > 0:
		visual_pivot.scale.x = abs(visual_pivot.scale.x)

# -------------------------------------------------------------
# 内部双向栅栏（Barrier）逻辑
# -------------------------------------------------------------
func _on_vector_stack_finished() -> void:
	if _is_dynamic_stream: return # 动态流不参与完结屏障
	_vector_done = true
	_check_action_completion()


func _on_anim_stack_finished() -> void:
	if _is_dynamic_stream: return # 动态流不参与完结屏障
	_anim_done = true
	_check_action_completion()


func _check_action_completion() -> void:
	# 🌟 只有当物理和动画【双双报告完成】时，管家才统一对外发声！
	if _vector_done and _anim_done:
		_vector_done = false
		_anim_done = false
		action_finished.emit() # 📢 通知外界（状态机）：当前静态动作彻底完结！
