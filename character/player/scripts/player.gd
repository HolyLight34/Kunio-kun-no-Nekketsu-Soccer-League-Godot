class_name Player
extends CharacterBody2D

enum Controller {
	P1,
	P2,
	CPU,
}

@export var controlled_by: Controller
@export var kick_power: float # 踢球的力量

var states: Array[State] # 状态数组
var current_state: State: # 当前状态
	get:
		return states.front()
var previous_state: State: # 上一个状态
	get:
		return states[1]
var facing_direction: Vector2 = Vector2.RIGHT # 面朝方向
var input_dir: Vector2 = Vector2.ZERO # 输入方向
var want_to_pass: bool = false
var want_to_run: bool = false
var want_to_shoot: bool = false
var is_carried: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var kick_area: Area2D = $KickArea
@onready var pick_up_area: Area2D = $PickUpArea
@onready var collision_shape_2d: CollisionShape2D = $KickArea/CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	current_state = %Idle
	initialize_states()
	add_to_group("players")
	pass


func _process(delta: float) -> void:
	change_state(current_state.process(delta))
	if current_state.can_flip:
		update_facing()
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


func update_facing() -> void: # 通过输入更新方向
	if input_dir.x != 0:
		# 方案 A：使用 Sprite 的 flip_h 属性（最简单）
		sprite_2d.flip_h = (input_dir.x < 0)
		facing_direction = Vector2.RIGHT if !sprite_2d.flip_h else Vector2.LEFT
	pass


func _on_pick_up_area_body_entered(body: Node) -> void: # 球拾取检测
	var ball = body as Ball
	if ball:
		ball.carrier = self
		is_carried = true
	pass # Replace with function body.
