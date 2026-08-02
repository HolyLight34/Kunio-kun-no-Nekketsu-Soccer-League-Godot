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
@export var player_id: int = 1

var has_ball: bool = false
## 🌟 实时获取角色的当前视觉面向（Vector2.RIGHT 或 Vector2.LEFT）
var facing_direction: Vector2:
	get:
		var s = sign(visual.scale.x) if visual else 1.0
		# 如果 scale.x == 0（极少情况），兜底为朝右 (Vector2.RIGHT)
		var dir_x = s if s != 0 else 1.0 
		return Vector2(dir_x, 0.0)
func get_facing_direction_supplier() -> Callable:
	# 🌟 返回一个 Lambda 闭包，每次被 .call() 时都会返回当前物理帧的最新的 move_dir
	return func() -> Vector2:
		return facing_direction
@export var endurance: int:
	set(value): # 💡 顺手帮你把拼写“vule”纠正为“value”
		if value < 0:
			value = 0
		endurance = value
		# ⚡ 防呆验证：只有当节点已经在场景树里、Label 加载完了，才去刷新 UI
		if is_inside_tree() and has_node("Label"):
			$Label.text = str(value)
# 这个变量由各个状态来修改
var target_velocity: Vector2 = Vector2.ZERO

@onready var visual: Node2D = $Visual
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var colliders: Node2D = $Colliders
@onready var hit_box: HitBox = $Colliders/HitBox
@onready var action_driver_component: ActionDriverComponent = $Components/ActionDriverComponent

@export var jump_action_data: TickActionData

func _ready() -> void:
	sm.init(self) # 状态机初始化
	$Label.text = str(endurance)
	pass


func _process(_delta: float) -> void:
	pass


func _physics_process(delta: float) -> void:
	var intent: IntentComponent.Intent = parser.get_intent()
	# 2. 告诉执行官：玩家想做这个，你处理一下。
	sm.handle_intent(intent, delta)
	#visual.position.y = -z_axis_component.z_pos
	pass

#endregion


func set_facing(direction: float) -> void:
	if direction == 0: return

	var sign_multiplier := 1.0 if direction > 0 else - 1.0

	# 1. 顶层命令：视觉文件夹，给我转！
	visual.scale.x = sign_multiplier
	# 2. 顶层命令：物理文件夹，你也给我转！
	colliders.scale.x = sign_multiplier
	


func _on_pickup_sensor_area_entered(area: Area2D) -> void:
	var ball: Ball = area.get_parent()
	ball.set_carried_by(self)
	has_ball = true
	pass # Replace with function body.


func _on_hurt_box_hit_received(incoming: HitBox) -> void:
	var player: Player = incoming.attacker
	if player == self:
		return
	if player.team_id == self.team_id:
		return
	endurance -= incoming.hit_info["damage"]
	pass # Replace with function body.
