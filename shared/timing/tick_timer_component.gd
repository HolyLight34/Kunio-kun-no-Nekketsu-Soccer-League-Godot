class_name TickTimerComponent
extends Node


signal timer_finished(timer_name: StringName)


@export var tick_component: TickComponent


# timer_name -> 剩余 Tick
var _timers: Dictionary[StringName, int] = {}


func _ready() -> void:
	if tick_component == null:
		push_error(
			"TickTimerComponent: tick_component 未设置"
		)
		return

	tick_component.tick_triggered.connect(
		_on_tick_triggered
	)


# ==============================================================================
# 外部接口
# ==============================================================================

## 开始一个倒计时。
##
## 如果同名计时器已经存在，则重新开始计时。
func start_timer(
	timer_name: StringName,
	ticks: int
) -> void:
	if ticks <= 0:
		timer_finished.emit(timer_name)
		return

	_timers[timer_name] = ticks


## 停止指定倒计时。
func stop_timer(timer_name: StringName) -> void:
	_timers.erase(timer_name)


## 停止全部倒计时。
func stop_all_timers() -> void:
	_timers.clear()


## 指定倒计时是否正在运行。
func is_timer_running(
	timer_name: StringName
) -> bool:
	return _timers.has(timer_name)


## 获取剩余 Tick。
##
## 不存在时返回 0。
func get_remaining_ticks(
	timer_name: StringName
) -> int:
	return _timers.get(timer_name, 0)


# ==============================================================================
# Tick
# ==============================================================================

func _on_tick_triggered() -> void:
	if _timers.is_empty():
		return

	var finished_timers: Array[StringName] = []

	for timer_name: StringName in _timers:
		_timers[timer_name] -= 1

		if _timers[timer_name] <= 0:
			finished_timers.append(timer_name)

	for timer_name: StringName in finished_timers:
		_timers.erase(timer_name)
		timer_finished.emit(timer_name)
