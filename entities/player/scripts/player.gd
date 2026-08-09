class_name Player
extends CharacterBody2D

# ==============================================================================
# 1. 信号与枚举 (Signals & Enums)
# ==============================================================================
enum Dir {
	NONE = -1,
	RIGHT = 0,
	DOWN_RIGHT = 1,
	DOWN = 2,
	DOWN_LEFT = 3,
	LEFT = 4,
	UP_LEFT = 5,
	UP = 6,
	UP_RIGHT = 7,
}

# ==============================================================================
# 2. 常量配置 (Constants)
# ==============================================================================
# --- 正向速度与加速度 (Cardinal) ---
const CARDINAL_SPEED_X: float = 2.375
const CARDINAL_SPEED_Y: float = 2.375
const CARDINAL_ACCEL_STEP: float = 0.046875

# --- 斜向速度与加速度 (Diagonal) ---
const DIAGONAL_SPEED_A: float = 1.67578125
const DIAGONAL_SPEED_B: float = 1.68359375
const DIAGONAL_ACCEL_STEP: float = 0.03125

# --- 跳跃预设速度向量 (Jump Impulse Presets) ---
const JUMP_SPEED_Y: float = 1.234375
const JUMP_VELOCITY_UP_LEFT: Vector2 = Vector2(-1.71484375, -0.875)
const JUMP_VELOCITY_UP_RIGHT: Vector2 = Vector2(1.70703125, -0.875)
const JUMP_VELOCITY_DOWN_LEFT: Vector2 = Vector2(-1.71484375, 0.8671875)
const JUMP_VELOCITY_DOWN_RIGHT: Vector2 = Vector2(1.70703125, 0.8671875)

# --- 衰减步长 (Deceleration) ---
const DECEL_STEP_X: float = 0.75

# ==============================================================================
# 3. 导出变量 (Export Variables)
# ==============================================================================
@export var team_id: MatchManager.Team
@export var player_id: int = 1

@export_group("Components")
@export var input_component: InputComponent
@export var parser: IntentComponent
@export var sm: StateMachine

@export var endurance: int:
	set(value):
		endurance = max(0, value)
		if is_inside_tree() and has_node("Label"):
			$Label.text = str(endurance)

# ==============================================================================
# 4. 节点引用与运行状态 (Onready & Variables)
# ==============================================================================
@onready var z_axis_component: ZAxisComponent = $Components/ZAxisComponent
@onready var step_animation_component: StepAnimationComponent = $Components/StepAnimationComponent
@onready var tick_component: TickComponent = $Components/TickComponent
@onready var visual: Node2D = $Visual
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var colliders: Node2D = $Colliders
@onready var hit_box: HitBox = $Colliders/HitBox

# 动态状态
var facing_direction: int = 1  # 当前朝向：1 为朝右，-1 为朝左
var speed_vector: Vector2 = Vector2.ZERO
var has_ball: bool = false
var pending_delay_ticks: int = 0
var is_transition_pending: bool = false

# ==============================================================================
# 5. 生命周期 (Engine Lifecycle)
# ==============================================================================
func _ready() -> void:
	sm.init(self)
	$Label.text = str(endurance)
	
	# 绑定组件信号
	tick_component.tick_triggered.connect(_on_3_tick)
	z_axis_component.landed.connect(_on_landed)
	sm.tick_reset_requested.connect(tick_component.reset_tick)

func _physics_process(delta: float) -> void:
	var intent: IntentComponent.Intent = parser.get_intent()
	sm.handle_intent(intent, delta)

# ==============================================================================
# 6. 核心 Tick 与移动逻辑 (Tick & Movement)
# ==============================================================================
func _on_3_tick() -> void:
	print(speed_vector)
	if sm.is_waiting_delay:
		return
				
	step_animation_component.advance_tick()
	z_axis_component.process_z_step()
	sm.physics_tick()
	#if sm.current_state.can_move:
		#if z_axis_component.is_in_air:
			#_process_air_movement()
		#else:
			#_process_ground_movement()
	_handle_facing(input_component.move_dir.x)
	_apply_physics_movement()
func apply_x_deceleration(rate: float) -> void:
	# 1. 先把 Y 轴清零
	speed_vector.y = 0.0
	# 2. 对 X 轴做 step 衰减
	speed_vector.x = move_toward(speed_vector.x, 0.0, rate)

## 🌟 2. 统一物理应用（物理执行层：每一帧/Tick 统一调用）
func _apply_physics_movement() -> void:
	# 只要当前 speed_vector 不为 0（无论是走路、惯性滑行、还是被击退），就触发物理移动
	if not speed_vector.is_zero_approx():
		move_and_collide(speed_vector)

## 开始跳跃
func start_jump() -> void:
	speed_vector = calculate_jump_velocity(input_component.move_dir)
	z_axis_component.apply_impulse(4.0)

## 落地回调
func _on_landed(_impact_velocity: float) -> void:
	speed_vector = Vector2.ZERO

# ==============================================================================
# 7. 朝向控制 (Facing Control)
# ==============================================================================
## 处理贴图转向的主入口
func _handle_facing(move_input_x: float) -> void:
	if move_input_x == 0:
		return
		
	if sm.is_waiting_delay:
		return
		
	var current_state_node := sm.current_state as EntityState
	if not current_state_node:
		return
		
	if current_state_node.facing_mode == PlayerState.FacingMode.LOCK:
		return

	var new_facing := 1 if move_input_x > 0 else -1
	if new_facing != facing_direction:
		facing_direction = new_facing
		_apply_sprite_flip(facing_direction)


## 执行真正的节点镜像翻转
func _apply_sprite_flip(dir: int) -> void:
	var sign_multiplier := float(dir)
	visual.scale.x = abs(visual.scale.x) * sign_multiplier
	colliders.scale.x = abs(colliders.scale.x) * sign_multiplier

# ==============================================================================
# 8. 工具与 8 方向算法 (Utilities & Movement Math)
# ==============================================================================
func get_dir_index(input_dir: Vector2) -> Dir:
	if input_dir.is_zero_approx():
		return Dir.NONE
	var angle := fposmod(input_dir.angle(), TAU)
	return wrapi(int(round(angle / (PI / 4.0))), 0, 8) as Dir

func is_diagonal_dir(input_dir: Vector2) -> bool:
	var dir := get_dir_index(input_dir)
	return dir != Dir.NONE and (int(dir) % 2 != 0)

## 计算地面 8 方向走路速度
func calculate_walk_velocity(input_dir: Vector2) -> Vector2:
	var dir := get_dir_index(input_dir)
	match dir:
		Dir.RIGHT: return Vector2(CARDINAL_SPEED_X, 0.0)
		Dir.DOWN_RIGHT: return Vector2(DIAGONAL_SPEED_A, DIAGONAL_SPEED_A)
		Dir.DOWN: return Vector2(0.0, CARDINAL_SPEED_Y)
		Dir.DOWN_LEFT: return Vector2(-DIAGONAL_SPEED_B, DIAGONAL_SPEED_A)
		Dir.LEFT: return Vector2(-CARDINAL_SPEED_X, 0.0)
		Dir.UP_LEFT: return Vector2(-DIAGONAL_SPEED_B, -DIAGONAL_SPEED_B)
		Dir.UP: return Vector2(0.0, -CARDINAL_SPEED_Y)
		Dir.UP_RIGHT: return Vector2(DIAGONAL_SPEED_A, -DIAGONAL_SPEED_B)
		_: return speed_vector

## 计算起跳瞬间的 X/Y 轴平面初始速度
func calculate_jump_velocity(input_dir: Vector2) -> Vector2:
	var dir := get_dir_index(input_dir)
	match dir:
		Dir.RIGHT: return Vector2(CARDINAL_SPEED_X, 0.0)
		Dir.DOWN_RIGHT: return JUMP_VELOCITY_DOWN_RIGHT
		Dir.DOWN: return Vector2(0.0, JUMP_SPEED_Y)
		Dir.DOWN_LEFT: return JUMP_VELOCITY_DOWN_LEFT
		Dir.LEFT: return Vector2(-CARDINAL_SPEED_X, 0.0)
		Dir.UP_LEFT: return JUMP_VELOCITY_UP_LEFT
		Dir.UP: return Vector2(0.0, -JUMP_SPEED_Y)
		Dir.UP_RIGHT: return JUMP_VELOCITY_UP_RIGHT
		_: return speed_vector

# ==============================================================================
# 9. 信号回调处理 (Signal Callbacks)
# ==============================================================================
func _on_pickup_sensor_area_entered(area: Area2D) -> void:
	var ball: Ball = area.get_parent()
	ball.set_carried_by(self)
	has_ball = true

func _on_hurt_box_hit_received(incoming: HitBox) -> void:
	var player: Player = incoming.attacker
	if player == self or player.team_id == self.team_id:
		return
	endurance -= incoming.hit_info["damage"]
