class_name Player
extends CharacterBody2D

# ==============================================================================
# 1. 信号与枚举 (Signals & Enums)
# ==============================================================================
# ==============================================================================
@export var team_id: MatchManager.Team
@export var player_id: int = 1
@onready var player_horizontal_movement: PlayerHorizontalMovement = $Components/PlayerHorizontalMovement

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

@onready var step_animation_component: StepAnimationComponent = $Components/StepAnimationComponent
@onready var tick_component: TickComponent = $Components/TickComponent
@onready var visual: Node2D = $Visual
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var colliders: Node2D = $Colliders
@onready var hit_box: HitBox = $Colliders/HitBox
@onready var player_z_movement: PlayerZMovement = $Components/PlayerZMovement
@onready var entity_visual_controller: EntityVisualController = $Components/EntityVisualController
@onready var ball_anchor: Marker2D = $Colliders/ball_anchor
@onready var pickup_sensor: Area2D = $Colliders/PickupSensor


# 动态状态
var facing_direction: Vector2  # 当前朝向：1 为朝右，-1 为朝左
var speed_vector: Vector2 = Vector2.ZERO
var pending_delay_ticks: int = 0
var is_transition_pending: bool = false
var carried_ball: Ball
func release_ball() -> void:
	print(carried_ball)
	if carried_ball == null:
		return
	carried_ball.release_from_carrier()
	carried_ball = null
func _initialize_components() -> void:
	player_horizontal_movement.set_horizontal_position(
		position
	)
	player_z_movement.set_z_height(visual.position.y)
	entity_visual_controller.initialize()
	sm.init(self)
# ==============================================================================
# 5. 生命周期 (Engine Lifecycle)
# ==============================================================================
func _ready() -> void:
	_initialize_components()
	$Label.text = str(endurance)
	# 绑定组件信号
	tick_component.tick_triggered.connect(_on_3_tick)
	#z_axis_component.landed.connect(_on_landed)
	sm.tick_reset_requested.connect(tick_component.reset_tick)

func _physics_process(delta: float) -> void:
	var intent: IntentComponent.Intent = parser.get_intent()
	sm.handle_intent(intent, delta)

# ==============================================================================
# 6. 核心 Tick 与移动逻辑 (Tick & Movement)
# ==============================================================================

func _on_3_tick() -> void:
	sm.physics_tick()
	step_animation_component.advance_tick()
	player_z_movement.process_z_step()
	_handle_facing(input_component.move_dir.x)
	player_horizontal_movement.step_logic_tick()
func apply_x_deceleration(rate: float) -> void:
	# 1. 先把 Y 轴清零
	player_horizontal_movement.planar_velocity.y = 0.0
	# 2. 对 X 轴做 step 衰减
	player_horizontal_movement.planar_velocity.x = move_toward(player_horizontal_movement.planar_velocity.x, 0.0, rate)

func get_ball_anchor_offset() -> Vector2:
	var offset := ball_anchor.position
	offset.x *= facing_direction.x
	return offset
# ==============================================================================
# 7. 朝向控制 (Facing Control)
# ==============================================================================
## 处理贴图转向的主入口
func _handle_facing(move_input_x: float) -> void:
	if move_input_x == 0:
		return
	var current_state_node := sm.current_state as EntityState
	if not current_state_node:
		return
		
	if current_state_node.facing_mode == PlayerState.FacingMode.LOCK:
		return

	var new_facing := Vector2.RIGHT if move_input_x > 0 else Vector2.LEFT
	if new_facing != facing_direction:
		facing_direction = new_facing
		_apply_sprite_flip(facing_direction)


## 执行真正的节点镜像翻转
func _apply_sprite_flip(dir: Vector2) -> void:
	visual.scale.x = abs(visual.scale.x) * dir.x
	colliders.scale.x = abs(colliders.scale.x) * dir.x


# ==============================================================================
# 9. 信号回调处理 (Signal Callbacks)
# ==============================================================================
func _on_pickup_sensor_area_entered(area: Area2D) -> void:
	var ball: Ball = area.get_parent()
	ball.set_carried_by(self)
	carried_ball = ball

func _on_hurt_box_hit_received(incoming: HitBox) -> void:
	var player: Player = incoming.attacker
	if player == self or player.team_id == self.team_id:
		return
	release_ball()
	endurance -= incoming.hit_info.damage
	sm.change_state(PlayerState.State.HURT,incoming.hit_info)
	
