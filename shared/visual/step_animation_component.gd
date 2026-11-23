class_name StepAnimationComponent
extends Node


const TICK_DELTA: float = 0.05


@export var animation_player: AnimationPlayer


var current_anim: StringName = &""
var is_playing: bool = false

## 当前动画已经播到的逻辑 Tick 数（从 1 开始）。
var current_tick_count: int = 0

## 是否等待本帧的 logic_tick 显示动画初始帧。
var _pending_start: bool = false

## 外部指定的目标持续 Tick 数（-1 表示按动画自身长度计算）。
var _target_total_ticks: int = -1


func _ready() -> void:
	if animation_player:
		animation_player.callback_mode_process = \
			AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

		animation_player.callback_mode_method = \
			AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE


## 播放指定动画。
## duration_ticks > 0 时，按指定 Tick 数作为结束时机（即使动画本身只有 1 帧）。
func play(
	anim_name: StringName,
	duration_ticks: int = -1
) -> void:
	if current_anim == anim_name and is_playing:
		return

	if not animation_player or not animation_player.has_animation(anim_name):
		push_warning(
			"StepAnimationComponent: 未找到动画 ",
			anim_name
		)
		return

	current_anim = anim_name
	is_playing = true
	current_tick_count = 1
	_pending_start = true
	_target_total_ticks = duration_ticks

	animation_player.play(anim_name)
	animation_player.seek(0.0, false)


## 当前单次动画是否已经播放完成。
func is_finished() -> bool:
	return not is_playing


## 由 FCLogicClock 驱动，在 StateMachine.logic_tick() 之后调用。
func logic_tick() -> void:
	if not animation_player or current_anim.is_empty() or not is_playing:
		return

	var anim_name := current_anim
	var anim := animation_player.get_animation(anim_name)
	if not anim:
		return

	var total_ticks: int
	if _target_total_ticks > 0:
		total_ticks = _target_total_ticks
	else:
		total_ticks = maxi(1, int(roundi(anim.length / TICK_DELTA)))

	var is_looping := (anim.loop_mode != Animation.LOOP_NONE and _target_total_ticks <= 0)

	# 新动画第一次推进：显示第 0 帧（即第 1 个 Tick）
	if _pending_start:
		_pending_start = false
		animation_player.seek(0.0, true)

		# 如果总共只有 1 帧，本帧显示完就标记结束，下一帧状态机就会立刻切走
		if total_ticks == 1 and not is_looping:
			is_playing = false
		return

	# 推进到下一逻辑帧
	current_tick_count += 1

	var has_finished := false
	if current_tick_count >= total_ticks:
		if is_looping:
			current_tick_count %= total_ticks
		else:
			current_tick_count = total_ticks
			has_finished = true

	animation_player.advance(TICK_DELTA)

	if current_anim != anim_name:
		return

	if has_finished:
		is_playing = false
