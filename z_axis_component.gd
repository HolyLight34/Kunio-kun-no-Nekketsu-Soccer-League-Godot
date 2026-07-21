class_name ZAxisComponent
extends Node

## =====================================================================
## 📡 信号接口 (Signals - 人球通用)
## =====================================================================
signal motion_started(target_height: int)          # 运动开始（起跳/起脚腾空）
signal peak_reached(current_z: int)                # 到达顶峰（可用于头球判定/足球最高点）
signal falling_started                             # 开始下落
signal grounded                                    # 落地瞬间（触发地面碰撞/落地特效）
signal motion_overridden(current_z: int)           # 运动被外力改变（如空中对抗、球被二次击打）

## =====================================================================
## ⚙️ 核心配置与状态 (Configuration & State)
## =====================================================================
enum State { 
	GROUNDED,   # 地面（Z = 0）
	RISING,     # 上升中
	PEAK_HOLD,  # 顶点滞留（滞空期）
	FALLING     # 下落中
}

const FRAMES_PER_TICK: int = 3                     # 物理帧分频节奏

var z_pos: int = 0                                 # 当前 Z 轴高度 (人球通用)
var current_state: State = State.GROUNDED          # 当前所处状态

var _frame_counter: int = 0                        # 帧分频计时器
var _peak_hold_timer: int = 0                      # 滞空已进行的帧数
var _peak_hold_duration_frames: int = 0            # 滞空总目标帧数

## 全局唯一的运动步进队列
var _remaining_steps: Array[int] = []

# =====================================================================
# 🌐 外部控制接口 (Public API - 通用控制)
# =====================================================================

## 1. 启动运动（无论是人起跳，还是球被踢飞）
func launch_motion(target_height: int, hold_ticks: int = 2) -> void:
	if target_height <= 0: return
	
	var seq = _calculate_motion_sequence(target_height)
	if seq.is_empty(): return
	
	_remaining_steps = seq
	_reset_counters()
	_peak_hold_duration_frames = hold_ticks * FRAMES_PER_TICK
	
	z_pos = 0
	current_state = State.RISING
	
	motion_started.emit(target_height)
	_execute_initial_step()
	_frame_counter = 1


## 2. 🌟 重定向/强行改变运动（人空中被打断，或者足球在空中被二次击打/撞击）
## @param extra_height: 附加高度（0 表示原地坠落，>0 表示带上劲向上弹飞）
func override_motion(extra_height: int = 0) -> void:
	if current_state == State.GROUNDED and z_pos == 0:
		return
		
	print("[ZAxis 通用] 在高度 ", z_pos, " 处运动轨迹被改变！")
	_reset_counters()
	motion_overridden.emit(z_pos)
	
	if extra_height > 0:
		# 二次向上腾空（例如球在半空又被顶了一脚，或者人被上勾拳打飞）
		var total_target = z_pos + extra_height
		_remaining_steps = _calculate_motion_sequence(total_target)
		current_state = State.RISING
		_execute_initial_step()
		_frame_counter = 1
	else:
		# 直接坠落（例如球落地弹起、或者人被击落）
		_remaining_steps = _calculate_motion_sequence(z_pos)
		current_state = State.FALLING
		falling_started.emit()
		_execute_initial_step()
		_frame_counter = 1


# =====================================================================
# 🔄 生命周期驱动 (Lifecycle & Physics Process)
# =====================================================================

func _physics_process(_delta: float) -> void:
	
	if current_state == State.GROUNDED:
		return
	if current_state == State.PEAK_HOLD:
		_handle_peak_hold()
		return

	if _frame_counter == 0:
		match current_state:
			State.RISING:
				_step_rising()
			State.FALLING:
				_step_falling()

	_frame_counter = (_frame_counter + 1) % FRAMES_PER_TICK


# =====================================================================
# 🔧 内部私有方法 (Private Methods)
# =====================================================================

func _execute_initial_step() -> void:
	if _remaining_steps.is_empty(): return
		
	if current_state == State.RISING:
		z_pos += _remaining_steps.pop_back()
	elif current_state == State.FALLING:
		z_pos -= _remaining_steps.pop_front()
	
	print("[逻辑层] 物理帧: ", Engine.get_physics_frames(), " | 初始步进 | 高度: ", z_pos)


func _step_rising() -> void:
	if not _remaining_steps.is_empty():
		z_pos += _remaining_steps.pop_back()
		print("[逻辑层] 物理帧: ", Engine.get_physics_frames(), " | 上升 | 高度: ", z_pos)
		
		if _remaining_steps.is_empty():
			current_state = State.PEAK_HOLD
			peak_reached.emit(z_pos)


func _step_falling() -> void:
	if not _remaining_steps.is_empty():
		z_pos -= _remaining_steps.pop_front()
		print("[逻辑层] 物理帧: ", Engine.get_physics_frames(), " | 下降 | 高度: ", z_pos)
		
		if _remaining_steps.is_empty():
			z_pos = 0
			current_state = State.GROUNDED
			grounded.emit()
	else:
		z_pos = 0
		current_state = State.GROUNDED
		grounded.emit()


func _handle_peak_hold() -> void:
	if _peak_hold_timer < _peak_hold_duration_frames:
		_peak_hold_timer += 1
	else:
		current_state = State.FALLING
		_reset_counters()
		falling_started.emit()
		
		# 完美对称：以当前顶峰高度重新生成下落曲线
		_remaining_steps = _calculate_motion_sequence(z_pos)
		_execute_initial_step()
		_frame_counter = 1


func _reset_counters() -> void:
	_frame_counter = 1
	_peak_hold_timer = 1


## 抛物线位移算法引擎
func _calculate_motion_sequence(target_height: int) -> Array[int]:
	if target_height <= 0: return []
	
	var current_h: int = 0
	var seq: Array[int] = []
	var cycle: int = 0
	
	while current_h < target_height:
		var step_a: int = 2 * cycle + 1
		var step_b: int = 2 * cycle + 2
		
		for i in range(3):
			var next_h = current_h + step_a
			if next_h <= target_height:
				seq.append(step_a)
				current_h = next_h
				if current_h == target_height: return seq
			else:
				seq.append(target_height - current_h)
				return seq
				
		var next_h = current_h + step_b
		if next_h <= target_height:
			seq.append(step_b)
			current_h = next_h
			if current_h == target_height: return seq
		else:
			seq.append(target_height - current_h)
			return seq
			
		cycle += 1
		
	return seq
func log_anim_frame(anim_name: String, frame_id: int):
	print("[动画层] 动画: ", anim_name, " | 帧ID: ", frame_id, " | 物理帧: ", Engine.get_physics_frames())
