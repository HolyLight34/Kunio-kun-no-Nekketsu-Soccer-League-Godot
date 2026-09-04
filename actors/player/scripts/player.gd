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
enum HurtType {
	NORMAL,
	HEAVY,
}
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
	var source: Player = incoming.source
	if source == self or source.team_id == self.team_id:
		return
	release_ball()
	var hurt_type: Types.HurtType = Types.HurtType.NORMAL
	var hurt_data: HurtData 
	if source.endurance + 8 >= endurance:
		hurt_type = Types.HurtType.HEAVY
		hurt_data = _create_hurt_data(incoming.hit_info,hurt_type)
	hurt_data = _create_normal_hurt_data(incoming.hit_info.attack_direction)
	endurance -= incoming.hit_info.damage
	sm.change_state(PlayerState.State.HURT,hurt_data)
	
func _on_hit_box_hit(hurt_box: HurtBox) -> void:
	var target: Player = hurt_box.target
	if target == self or target.team_id == self.team_id:
		return
	var hurt_data: HurtData 
	hurt_data = _create_normal_hurt_data(-facing_direction)
	if endurance + 8 < target.endurance:
		print(hurt_data.knockback_direction,hurt_data.knockback_speed)
		sm.change_state(PlayerState.State.HURT,hurt_data)
	pass # Replace with function body.
func _create_hurt_data(
	hit_info: HitInfo,
	hurt_type: Types.HurtType
) -> HurtData:
	var hurt_data := HurtData.new()
	hurt_data.hurt_type = hurt_type
	hurt_data.knockback_direction = _calculate_knockback_direction(
		hit_info.attack_direction,
		input_component.last_move_direction
	)
	hurt_data.knockback_speed = hit_info.knockback_speed
	hurt_data.z_velocity = hit_info.z_velocity
	return hurt_data
func _calculate_knockback_direction(
	attack_direction: Vector2,
	last_move_direction: Vector2
) -> Vector2:
	if last_move_direction.x != 0 and last_move_direction.y != 0:
		var same_horizontal_direction := (
			last_move_direction.x * attack_direction.x > 0
		)
		return (
			last_move_direction
			if same_horizontal_direction
			else -last_move_direction
		)
	if last_move_direction.x != 0:
		return attack_direction
	if last_move_direction.y != 0:
		return (
			Vector2.UP
			if attack_direction.x > 0
			else Vector2.DOWN
		)
	return attack_direction
func _create_normal_hurt_data(knockback_direction: Vector2) -> HurtData:
	var hurt_data := HurtData.new()
	hurt_data.hurt_type = Types.HurtType.NORMAL
	# 这里根据“我撞到 victim 后自己怎么弹”来算
	hurt_data.knockback_direction = knockback_direction
	hurt_data.knockback_speed = 6.0
	return hurt_data
