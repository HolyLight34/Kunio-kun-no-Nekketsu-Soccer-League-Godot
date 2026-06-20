class_name Ball
extends CharacterBody2D

@export var gravity: float = -800.0 # 重力加速度 (负值向上)
@export var bounce_factor: float = 0.6 # 弹力系数 (0.6 表示每次落地能量损耗 40%)
@onready var vh: VisualComponent = $VisualHandler
var kick_direction: int
var kick_power: float
# --- 【2.5D 物理核心参数】 ---
var z_height: float = 0.0      # 足球当前的绝对 Z 轴高度（单位：像素）
var z_velocity: float = 0.0    # 足球在 Z 轴方向的速度（正数向上飞，负数向下落）

# --- 【环境物理配置】 ---
@export var GRAVITY_Z: float = 980.0       # Z轴重力加速度
@export var BOUNCE_COEFF: float = 0.6      # 弹力系数（每次落地保留 60% 的速度反弹）
@export var FLOOR_FRICTION: float = 200.0  # 地面摩擦力（滚行时每秒减速多少）
var z_speed: float = 0.0 # 垂直速度
var last_kicker: Player # 上一个踢球者
var current_owner: Player = null # 足球携带者


var is_free: bool = true
var carrier: Player = null


# 球员脚下的“控球锚点”相对偏移（比如在球员身前 8 像素，高度 0 的草皮上）
const CARRY_OFFSET: Vector2 = Vector2(8, 0)

func _physics_process(_delta: float) -> void:
	if not is_free and carrier:
		# 关键：足球放弃自己的物理，坐标死死同步给持球人
		# 根据球员朝向，决定球在左脚还是右脚
		var facing_sign = sign(carrier.vh.scale.x)
		global_position = carrier.global_position + Vector2(CARRY_OFFSET.x * facing_sign, CARRY_OFFSET.y)
	else:
		# 自由球的普通滚动、摩擦力物理逻辑...
		move_and_slide()

# 被捡起时的切换接口
func set_carried_by(new_carrier: Player) -> void:
	is_free = false
	carrier = new_carrier
	velocity = Vector2.ZERO
	z_height = 0.0 # 落地

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
		carrier.ball_instance = null
		carrier = null
	kick_direction = initial_velocity
	kick_power = upward_force
	# 2. 把力道作为初始化参数，交给自己内部的 Launch 状态！
	# 3. 瞬间切入足球自己的 Launch 状态！
	sm.change_state(BallState.State.LAUNCH)
func _ready() -> void:
	$StateMachine.init(self)
	pass


func _process(_delta: float) -> void:
	pass
