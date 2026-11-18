class_name InputCommandMatcher
extends RefCounted


# ============================================================
# 配置
# ============================================================

## 方向双击允许的最大逻辑 Tick 间隔。
var double_tap_window: int = 15

## A、B 单键确认延迟（逻辑 Tick 数）。
const SINGLE_BUTTON_DELAY_TICKS: int = 1


# ============================================================
# 方向双击历史
# ============================================================

var _last_direction_bits: int = InputFrame.DirectionBits.NONE
var _last_direction_tick: int = -1


# ============================================================
# 按钮指令历史
# ============================================================

## 正在等待确认的单键指令。
var _pending_command: Types.PlayerCommandType = Types.PlayerCommandType.NONE

## 单键首次按下的逻辑 Tick。
var _pending_command_tick: int = -1

## 上一个逻辑 Tick 是否同时按住了 A+B。
var _was_ab_held: bool = false


# ============================================================
# 当前识别结果
# ============================================================

var _recognized_commands: Array[Types.PlayerCommandType] = []


# ============================================================
# 输入处理
# ============================================================

## 处理当前逻辑帧的输入快照。
func process_frame(frame: InputFrame) -> void:
	_recognized_commands.clear()

	_process_direction_input(
		frame.direction_bits,
		frame.logic_tick
	)

	_process_button_commands(frame)


# ============================================================
# 方向双击
# ============================================================

## 根据方向位和时间间隔识别方向双击。
func _process_direction_input(
	current_bits: int,
	current_tick: int
) -> void:
	if current_bits == InputFrame.DirectionBits.NONE:
		return

	var is_double_tap := false

	if _last_direction_tick >= 0:
		var interval := current_tick - _last_direction_tick

		if interval > 0 and interval <= double_tap_window:
			is_double_tap = (_last_direction_bits & current_bits) != 0

	_last_direction_bits = current_bits
	_last_direction_tick = current_tick

	if is_double_tap:
		_recognized_commands.append(Types.PlayerCommandType.DOUBLE_TAP)


# ============================================================
# 按钮指令
# ============================================================

## 识别 A、B 单键与 A+B 组合。
func _process_button_commands(frame: InputFrame) -> void:
	var is_a_held := frame.held_buttons.has(Types.InputButtonType.A)
	var is_b_held := frame.held_buttons.has(Types.InputButtonType.B)

	var is_a_pressed := frame.pressed_events.has(Types.InputButtonType.A)
	var is_b_pressed := frame.pressed_events.has(Types.InputButtonType.B)

	var is_ab_held := is_a_held and is_b_held

	# A+B 组合优先。
	if is_ab_held:
		if not _was_ab_held:
			_recognized_commands.append(Types.PlayerCommandType.A_B)

		# 组合成立，取消待确认的单键。
		_clear_pending_command()

		_was_ab_held = true
		return

	_was_ab_held = false

	# 记录首次按下的单键。
	if _pending_command == Types.PlayerCommandType.NONE:
		if is_a_pressed:
			_start_pending_command(Types.PlayerCommandType.A, frame.logic_tick)
		elif is_b_pressed:
			_start_pending_command(Types.PlayerCommandType.B, frame.logic_tick)

	# 没有待确认单键时直接返回。
	if _pending_command == Types.PlayerCommandType.NONE:
		return

	var interval := frame.logic_tick - _pending_command_tick

	if interval >= SINGLE_BUTTON_DELAY_TICKS:
		_recognized_commands.append(_pending_command)
		_clear_pending_command()


# ============================================================
# 单键等待管理
# ============================================================

## 开始等待单键确认。
func _start_pending_command(
	command: Types.PlayerCommandType,
	current_tick: int
) -> void:
	_pending_command = command
	_pending_command_tick = current_tick


## 清除待确认的单键。
func _clear_pending_command() -> void:
	_pending_command = Types.PlayerCommandType.NONE
	_pending_command_tick = -1


# ============================================================
# 结果获取
# ============================================================

## 返回当前逻辑帧识别出的指令。
func get_recognized_commands() -> Array[Types.PlayerCommandType]:
	return _recognized_commands.duplicate()


# ============================================================
# 重置
# ============================================================

## 清除所有输入识别历史。
func reset() -> void:
	_last_direction_bits = InputFrame.DirectionBits.NONE
	_last_direction_tick = -1

	_clear_pending_command()
	_was_ab_held = false

	_recognized_commands.clear()
