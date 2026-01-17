class_name Player
extends CharacterBody2D

enum Controller {
	P1,
	P2,
	CPU,
}
enum Action {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	PASS,
	# 传球/切换人（通常是A键）
	SHOOT,
	# 射门/铲球（通常是B键）
	START,
	# 暂停
	SELECT # 战术设置,,
}

@export var controlled_by: Controller = Controller.CPU
@export var kick_power: float # 踢球的力量

var states: Array[State] # 状态数组
var current_state: State: # 当前状态
	get:
		return states.front()
var previous_state: State: # 上一个状态
	get:
		return states[1]
var facing_direction: Vector2 = Vector2.RIGHT # 面朝方向
var direction: Vector2 = Vector2.ZERO # 输入方向
# 键映射向量
var key_to_vector: Dictionary
var p1_map: Dictionary = { Action.UP: "1p_up", Action.DOWN: "1p_down", Action.LEFT: "1p_left", Action.RIGHT: "1p_right", Action.SHOOT: "1p_shoot", Action.PASS: "1p_pass" }
var p2_map: Dictionary = { Action.UP: "2p_up", Action.DOWN: "2p_down", Action.LEFT: "2p_left", Action.RIGHT: "2p_right", Action.SHOOT: "2p_shoot", Action.PASS: "2p_pass" }
var direction_dic: Dictionary
var is_carried: bool = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var kick_area: Area2D = $KickArea
@onready var pick_up_area: Area2D = $PickUpArea
@onready var collision_shape_2d: CollisionShape2D = $KickArea/CollisionShape2D


func _ready() -> void:
	current_state = %Idle
	initialize_states()
	add_to_group("players")
	match controlled_by:
		Controller.P1:
			direction_dic = p1_map
			key_to_vector = {
				direction_dic[Action.LEFT]: Vector2.LEFT,
				direction_dic[Action.RIGHT]: Vector2.RIGHT,
				direction_dic[Action.UP]: Vector2.UP,
				direction_dic[Action.DOWN]: Vector2.DOWN,
			}

			pass
		Controller.P2:
			direction_dic = p2_map
			pass
		Controller.CPU:
			pass
	pass


func _process(delta: float) -> void:
	update_direction(direction_dic)
	change_state(current_state.process(delta))
	pass


func _physics_process(delta: float) -> void:
	change_state(current_state.physics_process(delta))
	move_and_slide()
	pass


func _unhandled_input(event: InputEvent) -> void:
	change_state(current_state.handle_input(event))
	pass


func initialize_states() -> void: # 状态机初始化
	states = []
	for c in $States.get_children():
		states.append(c)
		c.player = self
	if states.size() == 0:
		return
	for state in states:
		state.init()
	change_state(current_state)
	pass


func change_state(new_state: State) -> void: # 切换状态
	if new_state == null:
		return
	elif new_state == current_state:
		return
	if current_state:
		current_state.exit()
	states.push_front(new_state)
	current_state.enter()
	states.resize(3)
	pass


func update_direction(dic: Dictionary) -> void: # 通过输入更新方向
	direction = Input.get_vector(dic[Action.LEFT], dic[Action.RIGHT], dic[Action.UP], dic[Action.DOWN])
	if !current_state is StateRun:
		if direction == Vector2.LEFT:
			$Sprite2D.flip_h = true
		elif direction == Vector2.RIGHT:
			$Sprite2D.flip_h = false
	pass


func _on_pick_up_area_body_entered(body: Node) -> void: # 球拾取检测
	var ball = body as Ball
	if ball:
		ball.carrier = self
		is_carried = true
	pass # Replace with function body.
