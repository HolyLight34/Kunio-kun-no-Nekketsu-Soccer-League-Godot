class_name StepAnimationComponent
extends Node

signal animation_finished(anim_name: String)

@export var anim_player: AnimationPlayer

const TICK_DELTA: float = 0.05 # 0.05s

var current_anim: String = ""
var is_playing: bool = false

# 🌟 核心：用整数记录当前播到了第几个 Tick (0, 1, 2, 3...)
# 整数在计算机里是没有小数点和精度误差的！
var current_tick_count: int = 0

func _ready() -> void:
	if anim_player:
		anim_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		anim_player.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE

## 播放指定动画
func play(anim_name: String, force_restart: bool = false) -> void:
	if current_anim == anim_name and is_playing and not force_restart:
		return
	print(anim_name)
	if not anim_player or not anim_player.has_animation(anim_name):
		push_warning("StepAnimationComponent: 未找到动画 ", anim_name)
		return
		
	current_anim = anim_name
	is_playing = true
	current_tick_count = 0 # 👈 切动画时，整数计数器纯净归 0
	
	anim_player.assigned_animation = anim_name
	anim_player.seek(0.0, true)

## 由 3-Tick 驱动
func advance_tick() -> void:
	if not anim_player or current_anim.is_empty() or not is_playing:
		return
		
	var anim := anim_player.get_animation(current_anim)
	if not anim:
		return
		
	# 1. 算出现有动画“真正的”总 Tick 数 (纯整数！比如 1, 3, 5)
	var total_ticks: int = int(roundf(anim.length / TICK_DELTA))
	if total_ticks <= 0:
		total_ticks = 1 # 防御 0 长度动画
		
	# 2. 步进当前 Tick (1, 2, 3...)
	current_tick_count += 1
	var has_finished: bool = false
	
	# 3. 边界判断：直接比较整数 Tick，绝对没有 0.0500016 的干扰！
	if current_tick_count >= total_ticks:
		if anim.loop_mode != Animation.LOOP_NONE:
			# 循环动画：整数取余 (例如 1 % 1 = 0)
			current_tick_count = current_tick_count % total_ticks
		else:
			# 单次动画：锁定在最后一 Tick，标记结束
			current_tick_count = total_ticks
			has_finished = true
			
	# 4. 计算纯净的渲染时间推给 AnimationPlayer
	var render_pos := current_tick_count * TICK_DELTA
	anim_player.seek(render_pos, true)
	
	#print("当前 Tick: ", current_tick_count, " / 总 Tick: ", Engine.get_physics_frames(), " | 秒数: ", render_pos)
	
	if has_finished:
		is_playing = false
		animation_finished.emit(current_anim)
