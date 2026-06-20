class_name Player
extends CharacterBody2D

@export var stats: PlayerStats
@export var walk_speed: float = 30.0
@export var run_speed: float = 90.0
#region
@export_group("Components") # 在检查器里分个组，好看又清晰
@export var input: InputComponent # 引用输入组件
@export var parser: IntentComponent # 引用意图解析组件
@export var sm: StateMachine # 引用状态机（如果是自定义类可以写具体的类名）
@export var movement: MovementComponent
@export var vh: VisualComponent

var kick_power: float # 踢球的力量
var player_name: String = ""
var speed: float
var has_ball: bool = false
var ball_instance: Ball = null
var facing_direction: int:
	get:
		return sign(vh.scale.x) if vh.scale.x != 0 else 1

# 这个变量由各个状态来修改
var target_velocity: Vector2 = Vector2.ZERO
# Player.gd (球员脚本)
# 只有一行！利用“计算属性”直接映射，不需要写任何信号连接
var is_running: bool

@onready var kick_area: Area2D = $KickArea
@onready var pick_up_area: Area2D = $PickUpArea
@onready var collision_shape_2d: CollisionShape2D = $KickArea/CollisionShape2D

#endregion


func _ready() -> void:
	pick_up_area.body_entered.connect(_on_ball_entered_pickup_area)
	sm.init(self) # 状态机初始化
	add_to_group("players")
	# 1. 替换贴图
	#sprite_2d.texture = stats.sprite_sheet
	player_name = stats.player_name
	kick_power = stats.kick_power
	speed = stats.speed
	# 2. 动态设置分帧（确保 AnimationPlayer 播放的帧位置正确）
	#sprite_2d.hframes = stats.h_frames
	#sprite_2d.vframes = stats.v_frames

	pass

func _process(_delta: float) -> void:

	pass


func _physics_process(delta: float) -> void:
	# 状态机此时已经运行完毕，确定了 target_velocity
	#vh.update_facing(input.move_dir)
	var intent = parser.get_intent()

	# 2. 告诉执行官：玩家想做这个，你处理一下。
	sm.handle_intent(intent, delta)
	pass


	## 3. 命令状态机：老子拿到球了，立刻切换到带球静止状态！
	#sm.change_state(PlayerState.State.DRIBBLE_IDLE)
func _on_ball_entered_pickup_area(ball: Ball) -> void:
	## 1. 如果这个球正被别人带着，不能直接吸（必须等对方脱手或者被滑铲）
	if ball.carrier != null:
		return
	ball.set_carried_by(self)
	has_ball = true
	ball_instance = ball

	# 🎯 【核心智能路由】：根据当前的物理速度或输入，决定进化到哪个带球状态
	var current_speed = velocity.length()
	var input_dir = input.move_dir

	if input_dir == Vector2.ZERO and current_speed < 10.0:
		# 1. 情况一：原地站着，球被传过来了
		sm.change_state(PlayerState.State.DRIBBLE_IDLE)
	else:
		# 2. 情况二：人在运动中接到了球
		# 这里的判断标准取决于你的无球状态（如果你分了 Walk 和 Run）
		# 如果你当前正在 Run 状态，或者速度很快，就切到 DribbleRun
		if sm.current_state.name == "Run":
			sm.change_state(PlayerState.State.DRIBBLE_RUN)
		elif sm.current_state.name == "Walk":
			# 否则，如果是慢速走动，切到 DribbleWalk
			sm.change_state(PlayerState.State.DRIBBLE_WALK)
