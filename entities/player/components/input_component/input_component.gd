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

# --- 1. 方向意图 ---
var move_dir: Vector2 = Vector2.ZERO
var dir_up_just: bool = false
var dir_down_just: bool = false
var dir_left_just: bool = false
var dir_right_just: bool = false

# --- 2. A/B 键意图 ---
var btn_a: bool = false
var btn_a_just: bool = false
var btn_b: bool = false
var btn_b_just: bool = false

# --- 3. 系统按键 (更新：现在支持长按判定) ---
var btn_start: bool = false # 长按 Start
var btn_start_just: bool = false # 瞬按 Start

var btn_select: bool = false # 长按 Select
var btn_select_just: bool = false # 瞬按 Select


func _physics_process(_delta: float) -> void:
	# --- 方向处理 ---
	move_dir = Input.get_vector(action_left, action_right, action_up, action_down)
	dir_up_just = Input.is_action_just_pressed(action_up)
	dir_down_just = Input.is_action_just_pressed(action_down)
	dir_left_just = Input.is_action_just_pressed(action_left)
	dir_right_just = Input.is_action_just_pressed(action_right)

	# --- A/B 处理 ---
	btn_a = Input.is_action_pressed(action_a)
	btn_a_just = Input.is_action_just_pressed(action_a)
	btn_b = Input.is_action_pressed(action_b)
	btn_b_just = Input.is_action_just_pressed(action_b)

	# --- Start/Select 处理 (增加 is_action_pressed) ---
	btn_start = Input.is_action_pressed(action_start)
	btn_start_just = Input.is_action_just_pressed(action_start)

	btn_select = Input.is_action_pressed(action_select)
	btn_select_just = Input.is_action_just_pressed(action_select)
