class_name InputComponent
extends Node


const FUNCTION_BUTTONS: Array[Types.InputButtonType] = [
	Types.InputButtonType.A,
	Types.InputButtonType.B,
	Types.InputButtonType.START,
	Types.InputButtonType.SELECT,
]

@export_group("Input Actions")
@export var action_up: StringName = &"ui_up"
@export var action_down: StringName = &"ui_down"
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"

@export var action_a: StringName = &"btn_a"
@export var action_b: StringName = &"btn_b"
@export var action_start: StringName = &"btn_start"
@export var action_select: StringName = &"btn_select"

@export var player: Player


# ============================================================
# 当前输入状态
# ============================================================

## 是否启用玩家输入采集（AI 或非受控角色设为 false）。
var _is_input_enabled: bool = true

## 当前输入方向。
var input_direction: Vector2 = Vector2.ZERO

## 最后一次非零输入方向。
var last_input_direction: Vector2 = Vector2.RIGHT

## 当前处于按住状态的所有原始按键。
var _held_buttons: Array[Types.InputButtonType] = []


# ============================================================
# 待处理输入事件
# ============================================================

## 尚未交给 Logic Tick 的按下事件。
var _pending_pressed_events: Array[Types.InputButtonType] = []

## 尚未交给 Logic Tick 的释放事件。
var _pending_released_events: Array[Types.InputButtonType] = []


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	assert(player != null, "InputComponent: player 未设置")

	if player.player_id < 0 or player.player_id >= 3:
		set_input_enabled(false)
		return

	action_up = "p%d_move_up" % player.player_id
	action_down = "p%d_move_down" % player.player_id
	action_left = "p%d_move_left" % player.player_id
	action_right = "p%d_move_right" % player.player_id

	action_a = "p%d_button_a" % player.player_id
	action_b = "p%d_button_b" % player.player_id
	action_start = "p%d_button_start" % player.player_id
	action_select = "p%d_button_select" % player.player_id

	set_input_enabled(true)


# ============================================================
# 输入开关
# ============================================================

## 开启或关闭本角色的玩家输入采集。
func set_input_enabled(enabled: bool) -> void:
	_is_input_enabled = enabled
	set_process_input(enabled)

	if not enabled:
		input_direction = Vector2.ZERO
		_held_buttons.clear()
		_pending_pressed_events.clear()
		_pending_released_events.clear()


# ============================================================
# 原始输入事件采集
# ============================================================

## 接收原始输入事件。
func _input(event: InputEvent) -> void:
	if event.is_echo():
		return

	_record_event(event, action_up, Types.InputButtonType.UP)
	_record_event(event, action_down, Types.InputButtonType.DOWN)
	_record_event(event, action_left, Types.InputButtonType.LEFT)
	_record_event(event, action_right, Types.InputButtonType.RIGHT)

	_record_event(event, action_a, Types.InputButtonType.A)
	_record_event(event, action_b, Types.InputButtonType.B)
	_record_event(event, action_start, Types.InputButtonType.START)
	_record_event(event, action_select, Types.InputButtonType.SELECT)


## 记录按下和释放事件。
func _record_event(
	event: InputEvent,
	action: StringName,
	button_type: Types.InputButtonType
) -> void:
	if event.is_action_pressed(action):
		# 已经按住，不重复记录。
		if _held_buttons.has(button_type):
			return

		_held_buttons.append(button_type)
		_pending_pressed_events.append(button_type)
	# 
	elif event.is_action_released(action):
		# 过滤无对应按下的孤立/重复释放（如切窗口、切人控制或同动作多键绑定），保证按下与释放成对。
		if not _held_buttons.has(button_type):
			return

		_held_buttons.erase(button_type)
		_pending_released_events.append(button_type)


# ============================================================
# 移动方向采集
# ============================================================

## 在创建 Logic Tick 输入快照时更新。
func _update_move_direction() -> void:
	if not _is_input_enabled:
		input_direction = Vector2.ZERO
		return

	input_direction = Input.get_vector(
		action_left,
		action_right,
		action_up,
		action_down
	)

	if input_direction != Vector2.ZERO:
		last_input_direction = input_direction


# ============================================================
# 方向位合并
# ============================================================

## 将单个方向按键转换为方向位。
func _get_direction_bit(button_type: Types.InputButtonType) -> int:
	match button_type:
		Types.InputButtonType.RIGHT:
			return InputFrame.DirectionBits.RIGHT
		Types.InputButtonType.LEFT:
			return InputFrame.DirectionBits.LEFT
		Types.InputButtonType.DOWN:
			return InputFrame.DirectionBits.DOWN
		Types.InputButtonType.UP:
			return InputFrame.DirectionBits.UP
		_:
			return InputFrame.DirectionBits.NONE


## 合并当前逻辑帧内所有新方向输入。
func _collect_direction_bits() -> int:
	var direction_bits: int = InputFrame.DirectionBits.NONE

	for button_type in _pending_pressed_events:
		direction_bits |= _get_direction_bit(button_type)

	# 同轴反方向同时按下时相互抵消（与 Input.get_vector 及 FC 十字键逻辑一致）。
	const HORIZONTAL_MASK := InputFrame.DirectionBits.LEFT | InputFrame.DirectionBits.RIGHT
	const VERTICAL_MASK := InputFrame.DirectionBits.UP | InputFrame.DirectionBits.DOWN

	if (direction_bits & HORIZONTAL_MASK) == HORIZONTAL_MASK:
		direction_bits &= ~HORIZONTAL_MASK

	if (direction_bits & VERTICAL_MASK) == VERTICAL_MASK:
		direction_bits &= ~VERTICAL_MASK

	return direction_bits

# ============================================================
# 输入快照
# ============================================================

## 创建当前逻辑 Tick 的输入快照。
func create_input_frame(logic_tick: int) -> InputFrame:
	_update_move_direction()

	var frame := InputFrame.new()

	frame.logic_tick = logic_tick
	frame.input_direction = input_direction

	# 合并本 Tick 的方向按下事件。
	frame.direction_bits = _collect_direction_bits()

	# 当前持续按住的功能按钮。
	for button_type in FUNCTION_BUTTONS:
		if _held_buttons.has(button_type):
			frame.held_buttons.append(button_type)

	# 复制按下和释放事件。
	frame.pressed_events = _pending_pressed_events.duplicate()
	frame.released_events = _pending_released_events.duplicate()

	# 清理已经交付的瞬时事件。
	_pending_pressed_events.clear()
	_pending_released_events.clear()

	return frame


# ============================================================
# 公共接口
# ============================================================

## 获取当前移动方向。
func get_input_direction() -> Vector2:
	return input_direction
