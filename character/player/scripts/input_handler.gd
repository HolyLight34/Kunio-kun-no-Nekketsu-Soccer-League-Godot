extends Node

const DIRECTION_ACTIONS: Array = ["LEFT", "RIGHT", "UP", "DOWN"]

const DOUBLE_TAP_THRESHOLD: float = 0.25 # 双击判定的有效时间间隔（秒）
var last_tap_time: float = 0.0 # 上一次按键的时间戳
var last_action: String = "" # 上一次按下的方向名
var p1_map: Dictionary = { "UP": "1p_up", "DOWN": "1p_down", "LEFT": "1p_left", "RIGHT": "1p_right", "SHOOT": "1p_shoot", "PASS": "1p_pass" }
var p2_map: Dictionary = { "UP": "2p_up", "DOWN": "2p_down", "LEFT": "2p_left", "RIGHT": "2p_right", "SHOOT": "2p_shoot", "PASS": "2p_pass" }
var input_map: Dictionary

@onready var player = get_parent() # 获取父节点（球员）的引用


func _ready() -> void:
	match player.controlled_by:
		player.Controller.P1:
			input_map = p1_map
		player.Controller.P2:
			input_map = p2_map
		player.Controller.CPU:
			input_map = {}


func _process(_delta):
	if input_map.is_empty():
		return
	player.input_dir = Input.get_vector(input_map["LEFT"], input_map["RIGHT"], input_map["UP"], input_map["DOWN"])
	player.want_to_shoot = Input.is_action_just_pressed(input_map["SHOOT"])
	player.want_to_pass = Input.is_action_just_pressed(input_map["PASS"])
	# 双击奔跑检测
	for key in DIRECTION_ACTIONS:
		var action = input_map[key]
		if Input.is_action_just_pressed(action):
			handle_direction_tap(action)


func handle_direction_tap(action):
	var now = Time.get_ticks_msec() / 1000.0
	if action == last_action and now - last_tap_time < DOUBLE_TAP_THRESHOLD:
		player.want_to_run = true
		last_action = ""
	else:
		last_action = action
	last_tap_time = now
	
