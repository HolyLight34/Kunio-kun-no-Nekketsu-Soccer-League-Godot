class_name VectorStack
extends Node

## 📢 信号：当前所有数据栈（包括下落）消耗完毕且已完全落回地面
signal stack_finished
## 开始重力下落：[peak_height] 下落最高高度, [required_ticks] 下落所需总帧数
signal fall_started(peak_height: int, required_ticks: int)
## 📢 信号 1：角色刚刚落回地面（Z 轴归零）
signal landed() # 顺便可以把落下的高度/冲击力传出去，用来做不同程度的落地震动！
var _is_airborne: bool = false      ## 标记：角色当前是否在空中 (用于落地检测)
# 🌟 核心关联节点
var target_body: CharacterBody2D  # 地面物理碰撞实体 (XY 轴)
var visual_pivot: Node2D       # 角色视觉贴图容器 (Z 轴与镜像)

# 动态维护当前的 Z 轴高度 (像素)
var z_height: int = 0

# 数据栈与动态提供器
var _displacement_stack: Array[Vector3] = []
var continuous_supplier: Callable = Callable()

@export var debug_mode: bool = true   ## 是否开启控制台日志


# =============================================================
# 🚀 外部调用接口
# =============================================================

## 1. 装载有限固定序列（用于起跳、受击、滑铲）
func push_sequence(sequence: Array[Vector3],consume_immediately: bool = false) -> void:
	# 🌟 类内部调用自己的私有/回调函数，完全合规！
	if consume_immediately:
		_on_tick_triggered()
	_displacement_stack = sequence.duplicate()
	_displacement_stack.reverse()  # 翻转以便使用 pop_back() 弹出


## 2. 启动无限/动态流（用于长按方向键行走、跑步）
func start_continuous_stream(supplier: Callable) -> void:
	if continuous_supplier == supplier:
		return
	continuous_supplier = supplier


## 3. 清空物理位移栈（打断动作或切换状态时调用）
func reset() -> void:
	_displacement_stack.clear()
	continuous_supplier = Callable()


## 4. 重置 Z 轴高度助手
func reset_z_height() -> void:
	z_height = 0
	if visual_pivot:
		visual_pivot.position.y = 0.0


# =============================================================
# 🌟 核心驱动：由 Ticker 逐 Tick 触发消耗数据
# =============================================================

func _on_tick_triggered() -> void:
	# 1. 如果栈空了且有动态闭包（如行走），从闭包获取最新步进
	if _displacement_stack.is_empty() and continuous_supplier.is_valid():
		var next_steps: Array[Vector3] = continuous_supplier.call()
		if not next_steps.is_empty():
			_displacement_stack = next_steps

	# 2. 🌟 下落接管判定：
	# 如果当前栈为空、无动态流，且角色依然悬空 (z_height > 0)，
	# 说明静态动作（如跳跃上升段、高空受击击退）已播放完毕，自动生成重力下落序列接管！
	if _displacement_stack.is_empty() and not continuous_supplier.is_valid() and z_height > 0:
		_trigger_auto_fall()

	# 3. 如果栈依然是空的，静默返回，不触发完结信号
	if _displacement_stack.is_empty():
		return
	
	# 4. 弹出当前 Tick 的 3D 位移步进
	var step: Vector3 = _displacement_stack.pop_back()
	# 🌟 1. 记录步进前的空中状态 and 上一次高度（last_z）
	var was_airborne_before: bool = _is_airborne
	# 5. 将步进应用到物理与视觉节点
	_apply_step(step)
	_log_tick_info("物理驱动", step)
	# 6. 完结检查：只有当静态序列消耗完毕、无动态流、且彻底落回地面 (z_height == 0) 时才发出信号
	# 🌟 信号 B：队列空了（数据层面完结）
	var is_stack_empty = _displacement_stack.is_empty() and not continuous_supplier.is_valid()
	if is_stack_empty and z_height <= 0:
		stack_finished.emit() # 📢 专门通报给管家：步进队列完结
	# 🌟 触发落地信号的精准瞬间：原本在空中 + 现在 z_height 归零
	var just_landed = was_airborne_before and not _is_airborne
	if just_landed:
		landed.emit()


# =============================================================
# 🛠️ 内部逻辑与下落算法
# =============================================================

## 🌟 自动生成下落步进并压栈
func _trigger_auto_fall() -> void:
	# 🌟 靠数据判定：如果栈里已经有位移向量在消耗了，说明已经在下落/移动中，不需要重复触发！
	if not _displacement_stack.is_empty():
		return
		
	var fall_vectors = generate_fall_vectors(z_height)
	if not fall_vectors.is_empty():
		fall_started.emit(z_height,fall_vectors.size())
		push_sequence(fall_vectors)

## 🌟 核心：递增下落算法（生成负 Z 轴的 Vector3 数组）
func generate_fall_vectors(start_height: int) -> Array[Vector3]:
	var raw_seq = _generate_fall_sequence(start_height)
	var vector_seq: Array[Vector3] = []
	
	# 转换算法算出的正数像素为负 Z 轴（下落）的 Vector3
	for step_val in raw_seq:
		vector_seq.append(Vector3(0.0, 0.0, -float(step_val)))
		
	return vector_seq

## 🌟 递增加速下落数学算法（绝对精确匹配 start_height，防止穿模）
func _generate_fall_sequence(start_height: int) -> Array[int]:
	if start_height <= 0:
		return []
	
	var accumulated_distance: int = 0
	var sequence: Array[int] = []
	var cycle: int = 0
	
	while accumulated_distance < start_height:
		var minor_step: int = 2 * cycle + 1
		var major_step: int = 2 * cycle + 2
		
		# A. 追加 3 次基础步进 (minor_step)
		for i in range(3):
			if accumulated_distance + minor_step < start_height:
				sequence.append(minor_step)
				accumulated_distance += minor_step
			else:
				# 临近或刚好到达地面，直接追加剩余精细距离并返回
				sequence.append(start_height - accumulated_distance)
				return sequence
				
		# B. 追加 1 次峰值步进 (major_step)
		if accumulated_distance + major_step < start_height:
			sequence.append(major_step)
			accumulated_distance += major_step
		else:
			# 临近或刚好到达地面，直接追加剩余精细距离并返回
			sequence.append(start_height - accumulated_distance)
			return sequence
			
		cycle += 1
		
	return sequence


## 🌟 内部辅助：应用步进到物理和视觉
func _apply_step(step: Vector3) -> void:
	# -------------------------------------------------------------
	# 1. 应用 XY 轴地面物理位移
	# -------------------------------------------------------------
	if target_body and (step.x != 0.0 or step.y != 0.0):
		var xy_move = Vector2(step.x, step.y)
		target_body.move_and_collide(xy_move)

	# -------------------------------------------------------------
	# 2. 应用 Z 轴视觉高度偏移
	# -------------------------------------------------------------
	if step.z != 0.0 or z_height != 0:
		
		# 更新高度并截断最小值 0.0
		z_height = maxf(0.0, z_height + step.z)
		
		# 标记是否在空中
		if z_height > 0:
			_is_airborne = true
		
		# 🌟 核心判断：如果上一步还在空中（_was_airborne），这一步精准落回了地面（z_height == 0）
		if _is_airborne and z_height == 0:
			# 🌟 精准落地：同时重置两个空中标记！
			_is_airborne = false
		
		if visual_pivot:
			visual_pivot.position.y = -z_height

	# -------------------------------------------------------------
	# 3. 应用视觉镜像转向
	# -------------------------------------------------------------
	if visual_pivot and step.x != 0.0:
		if step.x < 0.0:
			visual_pivot.scale.x = -abs(visual_pivot.scale.x)
		else:
			visual_pivot.scale.x = abs(visual_pivot.scale.x)
# =============================================================
# 📜 日志助手
# =============================================================

func _log_tick_info(action_name: String, step: Vector3) -> void:
	if not debug_mode:
		return
		
	var tag_color = "cyan"
	if step.z > 0:
		tag_color = "yellow"   # 上升段
	elif step.z < 0:
		tag_color = "green"    # 下落段
	elif step.x != 0 or step.y != 0:
		tag_color = "magenta"  # 地面位移

	print_rich(
		"[color=%s][%s][/color] 物理帧: [color=gray]%d[/color] | 步进: %s | Z高度: [color=green]%.1f[/color] | 栈余量: %d" % [
			tag_color,
			action_name,
			Engine.get_physics_frames(),
			step,
			z_height,
			_displacement_stack.size()
		]
	)
