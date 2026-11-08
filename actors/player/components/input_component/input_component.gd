
class_name InputComponent
extends Node


@export_group("Input Actions")
@export var action_up: StringName = "ui_up"
@export var action_down: StringName = "ui_down"
@export var action_left: StringName = "ui_left"
@export var action_right: StringName = "ui_right"

@export var action_a: StringName = "btn_a"
@export var action_b: StringName = "btn_b"
@export var action_start: StringName = "btn_start"
@export var action_select: StringName = "btn_select"

@export var player: Player


# ============================================================
# 持续输入状态
# ============================================================

var move_dir: Vector2 = Vector2.ZERO
var last_move_direction: Vector2 = Vector2.RIGHT

var btn_a: bool = false
var btn_b: bool = false

var btn_start: bool = false
var btn_select: bool = false


# ============================================================
# 输入事件队列
#
# 只记录按下事件。
# 由 Logic Tick 消费。
# ============================================================

var _pending_pressed_events: Array[StringName] = []


func _ready() -> void:
	if player.player_id >= 3:
		return

	action_up = "p%d_move_up" % player.player_id
	action_down = "p%d_move_down" % player.player_id
	action_left = "p%d_move_left" % player.player_id
	action_right = "p%d_move_right" % player.player_id

	action_a = "p%d_button_a" % player.player_id
	action_b = "p%d_button_b" % player.player_id
	action_start = "p%d_button_start" % player.player_id
	action_select = "p%d_button_select" % player.player_id


## 每个 Physics Frame 采集一次输入
func _physics_process(_delta: float) -> void:
	_update_held_inputs()
	_collect_pressed_events()


## 更新持续输入
func _update_held_inputs() -> void:
	move_dir = Input.get_vector(
		action_left,
		action_right,
		action_up,
		action_down
	)

	if move_dir != Vector2.ZERO:
		last_move_direction = move_dir

	btn_a = Input.is_action_pressed(action_a)
	btn_b = Input.is_action_pressed(action_b)

	btn_start = Input.is_action_pressed(action_start)
	btn_select = Input.is_action_pressed(action_select)


## 收集瞬时按下事件
func _collect_pressed_events() -> void:
	_record_pressed(action_up, &"up")
	_record_pressed(action_down, &"down")
	_record_pressed(action_left, &"left")
	_record_pressed(action_right, &"right")

	_record_pressed(action_a, &"a")
	_record_pressed(action_b, &"b")

	_record_pressed(action_start, &"start")
	_record_pressed(action_select, &"select")


## 记录按键事件
func _record_pressed(
	action: StringName,
	event_name: StringName
) -> void:
	if Input.is_action_just_pressed(action):
		_pending_pressed_events.append(event_name)


## 获取并清空已经采集的输入事件
func consume_pressed_events() -> Array[StringName]:
	var events := _pending_pressed_events.duplicate()

	_pending_pressed_events.clear()

	return events


func get_move_direction() -> Vector2:
	return move_dir
