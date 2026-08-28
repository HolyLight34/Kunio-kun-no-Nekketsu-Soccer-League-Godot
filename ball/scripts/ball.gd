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
@onready var hit_box: HitBox = $HitBox

var z_speed: float = 0.0 # 垂直速度
#var last_kicker: Player # 上一个踢球者
var is_free: bool = true
var carrier: Player = null

const CARRY_OFFSET: Vector2 = Vector2(8, 0)
@onready var visual: Node2D = $Visual
@onready var step_animation_component: StepAnimationComponent = $StepAnimationComponent
var speed_vector: Vector2
@onready var ball_z_movement: BallZMovement = $BallZMovement
@onready var entity_visual_controller: EntityVisualController = $EntityVisualController


var is_counting_apex: bool = false
var apex_frame_timer: int = 0
var last_recorded_height: float = 0.0

func _on_3_tick() -> void:
	if sm.is_waiting_delay:
		return
				
	step_animation_component.advance_tick()
	ball_z_movement.process_z_step()
	
	sm.physics_tick()
	Log.debug(Log.Cat.PHYSICS,"物理帧：%d " % [Engine.get_physics_frames()])
	print(position)
	


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
@onready var pickup_area: Area2D = $PickupArea
@onready var tick_component: TickComponent = $TickComponent

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
	tick_component.tick_triggered.connect(_on_3_tick)
	# 打印出来的依然会是精确的 0.4375
	#print("实际运行的弹力系数为: ", z_axis_component.bounce_factor)
	#z_axis_component.apply_impulse(8)
	
	ball_z_movement.launch(8)
	#speed_vector = 8*Vector2.RIGHT
	#print(position)
	pass


func _process(_delta: float) -> void:
	pass


func _on_hurt_box_hit_received(incoming: HitBox) -> void:
	if incoming.hit_info.damage != 0:
		sm.change_state(BallState.State.SHOT)
		hit_box.hit_info = incoming.hit_info
	else :
		carrier = incoming.attacker
		sm.change_state(BallState.State.HOLD)
	pass # Replace with function body.
