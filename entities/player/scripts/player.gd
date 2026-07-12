class_name Player
extends CharacterBody2D
@export var team_id: MatchManager.Team
@export var walk_speed: float = 30.0
@export var run_speed: float = 90.0
#region
@export_group("Components") # 在检查器里分个组，好看又清晰
@export var input: InputComponent # 引用输入组件
@export var parser: IntentComponent # 引用意图解析组件
@export var sm: StateMachine # 引用状态机（如果是自定义类可以写具体的类名）
@export var movement: MovementComponent
@export var player_id: int = 1
var has_ball: bool = false
var facing_direction: int:
	get:
		return sign(visual.scale.x) if visual.scale.x != 0 else 1
var endurance: int #体力
# 这个变量由各个状态来修改
var target_velocity: Vector2 = Vector2.ZERO

@onready var visual: Node2D = $Visual
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var colliders: Node2D = $Colliders
@onready var hit_box: HitBox = $Colliders/HitBox

#endregion

func set_facing(direction: float) -> void:
	if direction == 0: return
	
	var sign_multiplier := 1.0 if direction > 0 else -1.0
	
	# 1. 顶层命令：视觉文件夹，给我转！
	visual.scale.x = sign_multiplier
	
	# 2. 顶层命令：物理文件夹，你也给我转！
	colliders.scale.x = sign_multiplier
	
	
func _ready() -> void:
	sm.init(self) # 状态机初始化
	pass

func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	var intent: IntentComponent.Intent = parser.get_intent()
	# 2. 告诉执行官：玩家想做这个，你处理一下。
	sm.handle_intent(intent, delta)
	pass


func _on_ball_picker_body_entered(body: Node2D) -> void:
	if body is not Ball:
		return
	print("我摸到球了")
	var ball: Ball = body
	if ball.sm.current_state.name == "Shot":
		return
	if ball.carrier != null:
		return
	ball.set_carried_by(self)
	has_ball = true
	pass # Replace with function body.
