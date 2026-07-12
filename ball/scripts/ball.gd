class_name Ball
extends CharacterBody2D

@export var gravity: float = -800.0 # 重力加速度 (负值向上)
@export var bounce_factor: float = 0.6 # 弹力系数 (0.6 表示每次落地能量损耗 40%)
var ball_force: float #（球威/球的冲力）
var kick_direction: int
var kick_power: float
# --- 【2.5D 物理核心参数】 ---
var z_height: float = 0.0      # 足球当前的绝对 Z 轴高度（单位：像素）
var z_velocity: float = 0.0    # 足球在 Z 轴方向的速度（正数向上飞，负数向下落）
## 📡 信号：球权被某人夺取了
signal possession_changed(new_carrier: Node)
## 📡 信号：球脱离了控制（被踢飞、漏球、无主滚动）
signal possession_lost()
# --- 【环境物理配置】 ---
@export var GRAVITY_Z: float = 980.0       # Z轴重力加速度
@export var BOUNCE_COEFF: float = 0.6      # 弹力系数（每次落地保留 60% 的速度反弹）
@export var FLOOR_FRICTION: float = 200.0  # 地面摩擦力（滚行时每秒减速多少）
@onready var hit_box: HitBox = $HitBox

var z_speed: float = 0.0 # 垂直速度
var last_kicker: Player # 上一个踢球者
var current_owner: Player = null # 足球携带者

var is_free: bool = true
var carrier: Player = null

const CARRY_OFFSET: Vector2 = Vector2(8, 0)

func _physics_process(_delta: float) -> void:
		move_and_slide()

# 被捡起时的切换接口
func set_carried_by(new_carrier: Player) -> void:
	is_free = false
	carrier = new_carrier
	velocity = Vector2.ZERO
	z_height = 0.0 # 落地
	sm.change_state(BallState.State.HOLD)

# 被踢出去或传出去时的释放接口
func release(initial_velocity: Vector2) -> void:
	is_free = true
	carrier = null
	velocity = initial_velocity
#region
@onready var sm: StateMachine = $StateMachine
@onready var camera_2d: Camera2D = $Camera2D
#endregion
func be_kicked(initial_velocity: int, upward_force: float) -> void:
	# 1. 彻底斩断和主人的联系（如果有的话）
	if carrier != null:
		carrier.has_ball = false
		#carrier.ball_instance = null
		carrier = null
	kick_direction = initial_velocity
	kick_power = upward_force
	# 2. 把力道作为初始化参数，交给自己内部的 Launch 状态！
	# 3. 瞬间切入足球自己的 Launch 状态！
	sm.change_state(BallState.State.SHOT)
func _ready() -> void:
	sm.init(self)
	pass


func _process(_delta: float) -> void:
	pass


func _on_hurt_box_hit_received(incoming_hit_box: HitBox) -> void:
	hit_box.setup(5, incoming_hit_box.knockback_force , incoming_hit_box.knockback_direction)
	sm.change_state(BallState.State.SHOT)
	pass # Replace with function body.
