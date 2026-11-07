
class_name StepAnimationComponent
extends Node


signal animation_finished(anim_name: String)


const TICK_DELTA: float = 0.05


@export var anim_player: AnimationPlayer


var current_anim: String = ""
var is_playing: bool = false

## 当前动画已经推进的逻辑 Tick 数。
var current_tick_count: int = 0

## 是否等待下一次逻辑帧显示动画初始帧。
var _pending_start: bool = false


func _ready() -> void:
	if anim_player:
		anim_player.callback_mode_process = \
			AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

		anim_player.callback_mode_method = \
			AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE


## 播放指定动画。
func play(anim_name: String, force_restart: bool = false) -> void:
	if current_anim == anim_name and is_playing and not force_restart:
		return

	if not anim_player or not anim_player.has_animation(anim_name):
		push_warning("StepAnimationComponent: 未找到动画 ", anim_name)
		return

	current_anim = anim_name
	is_playing = true
	current_tick_count = 0
	_pending_start = true

	anim_player.play(anim_name)
	anim_player.seek(0.0, false)


## 由 FCLogicClock 驱动，每个逻辑帧调用一次。
func advance_tick() -> void:
	#print("A：动画推进前",Engine.get_physics_frames())
	
	if not anim_player or current_anim.is_empty() or not is_playing:
		return

	var anim := anim_player.get_animation(current_anim)
	if not anim:
		return

	# 新动画第一次推进：显示第 0 帧，不增加 Tick。
	if _pending_start:
		_pending_start = false
		anim_player.seek(0.0, true)
		return

	# 计算动画总 Tick 数。
	var total_ticks: int = int(roundf(anim.length / TICK_DELTA))

	if total_ticks <= 0:
		total_ticks = 1

	# 推进一个逻辑 Tick。
	current_tick_count += 1

	var has_finished := false

	# 判断动画是否到达末尾。
	if current_tick_count >= total_ticks:
		if anim.loop_mode != Animation.LOOP_NONE:
			current_tick_count %= total_ticks
		else:
			current_tick_count = total_ticks
			has_finished = true

	# 将整数 Tick 转换为动画时间。
	var render_pos: float = current_tick_count * TICK_DELTA

	anim_player.seek(render_pos, true)

	# 单次动画播放结束。
	if has_finished:
		is_playing = false
		animation_finished.emit(current_anim)
	# 原来的动画推进代码
	#print("B：动画推进后",Engine.get_physics_frames())
