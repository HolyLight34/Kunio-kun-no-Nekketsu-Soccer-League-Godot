class_name FCLogicClock
extends Node


## FCLogicClock
##
## FC 游戏逻辑的统一时钟。
##
## 所有需要按照 FC 原版逻辑频率运行的对象，
## 都由本时钟统一驱动。
##
## 当前确认的逻辑频率为 20Hz：
##
##     1 tick = 1 / 20 秒 = 0.05 秒
##
## Player、Ball、AI 等对象不应各自创建 Timer
## 来决定自己的 FC 逻辑步。


signal logic_tick


const TICK_RATE := 20.0
const TICK_INTERVAL := 1.0 / TICK_RATE


var _accumulator := 0.0


func _physics_process(delta: float) -> void:
	_accumulator += delta

	while _accumulator >= TICK_INTERVAL:
		_accumulator -= TICK_INTERVAL
		step()


## 手动推进一个 FC 逻辑步。
##
## 除正常比赛外，也可以用于测试、回放等场景。
func step() -> void:
	
	logic_tick.emit()
