class_name Player
extends CharacterBody2D
# ==============================================================================
# 1. 配置
# ==============================================================================
@export var team_id: MatchManager.Team
@export var player_id: int = 1
@export_group("Components")
@export var input_component: InputComponent
@export var intent_component: IntentComponent
@export var state_machine: StateMachine
@export var endurance: int:
	set(value):
		endurance = max(0, value)

		if is_inside_tree() and has_node("Label"):
			$Label.text = str(endurance)
# ==============================================================================
# 2. 节点引用
# ==============================================================================
@onready var player_horizontal_movement: PlayerHorizontalMovement = (
	$Components/PlayerHorizontalMovement
)
@onready var player_z_movement: PlayerZMovement = (
	$Components/PlayerZMovement
)
@onready var step_animation_component: StepAnimationComponent = (
	$Components/StepAnimationComponent
)
@onready var tick_component: TickComponent = (
	$Components/TickComponent
)
@onready var entity_visual_controller: EntityVisualController = (
	$Components/EntityVisualController
)
@onready var visual: Node2D = $Visual
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var colliders: Node2D = $Colliders
@onready var hit_box: HitBox = $Colliders/HitBox
@onready var ball_anchor: Marker2D = $Colliders/BallAnchor
@onready var pickup_sensor: Area2D = $Colliders/PickupSensor
@onready var endurance_label: Label = $Label
# ==============================================================================
# 3. 运行状态
# ==============================================================================
var facing_direction: Vector2 = Vector2.RIGHT
var carried_ball: Ball
# ==============================================================================
# 4. 生命周期
# ==============================================================================
func _ready() -> void:
	_initialize_components()
	endurance_label.text = str(endurance)
	tick_component.tick_triggered.connect(_on_logic_tick)
	state_machine.tick_reset_requested.connect(
		tick_component.reset_tick
	)
func _physics_process(delta: float) -> void:
	var intent: IntentComponent.Intent = (
		intent_component.get_intent()
	)
	state_machine.handle_intent(intent, delta)
# ==============================================================================
# 5. 初始化
# ==============================================================================
func _initialize_components() -> void:
	player_horizontal_movement.set_horizontal_position(position)

	player_z_movement.set_z_height(
		visual.position.y
	)
	entity_visual_controller.initialize()
	state_machine.init(self)
# ==============================================================================
# 6. Logic Tick
# ==============================================================================
func _on_logic_tick() -> void:
	state_machine.physics_tick()
	step_animation_component.advance_tick()
	player_z_movement.process_z_step()
	_update_facing(
		input_component.move_dir.x
	)
	player_horizontal_movement.step_logic_tick()

# ==============================================================================
# 7. 朝向
# ==============================================================================
func _update_facing(move_input_x: float) -> void:
	if move_input_x == 0.0:
		return
	var current_state := (
		state_machine.current_state as EntityState
	)
	if current_state == null:
		return
	if current_state.facing_mode == PlayerState.FacingMode.LOCK:
		return
	var new_facing := (
		Vector2.RIGHT
		if move_input_x > 0.0
		else Vector2.LEFT
	)
	if new_facing == facing_direction:
		return
	facing_direction = new_facing
	_apply_facing()
func _apply_facing() -> void:
	visual.scale.x = (
		abs(visual.scale.x) * facing_direction.x
	)
	colliders.scale.x = (
		abs(colliders.scale.x) * facing_direction.x
	)
func get_ball_anchor_offset() -> Vector2:
	var offset := ball_anchor.position
	offset.x *= facing_direction.x
	return offset
# ==============================================================================
# 8. 持球
# ==============================================================================
func set_carried_ball(ball: Ball) -> void:
	carried_ball = ball
func release_ball() -> void:
	if carried_ball == null:
		return
	carried_ball.release_from_carrier()
	carried_ball = null
func _on_pickup_sensor_body_entered(body: Node2D) -> void:
	if body is not Ball:
		return
	var ball := body as Ball
	if not ball.can_be_picked_up():
		return
	ball.set_carried_by(self)
	carried_ball = ball
# ==============================================================================
# 9. 受击入口
# ==============================================================================
func _on_hurt_box_hit_received(incoming: HitBox) -> void:
	_receive_hit(incoming)
func _receive_hit(incoming: HitBox) -> void:
	if not _can_receive_hit(incoming):
		return
	var source := incoming.source as Player
	var hit_info := incoming.hit_info
	var hurt_data := _resolve_hurt_data(
		source,
		hit_info
	)
	if _should_source_rebound(source, hit_info):
		var source_rebound_data := _create_normal_hurt_data(
			-hit_info.attack_direction
		)
		source.receive_hurt(source_rebound_data)
	endurance -= hit_info.damage
	receive_hurt(hurt_data)
func _should_source_rebound(
	source: Player,
	hit_info: HitInfo
) -> bool:
	if hit_info.attack_type == Types.AttackType.SLIDE:
		return false

	return source.endurance + 8 < endurance
func receive_hurt(hurt_data: HurtData) -> void:
	release_ball()
	state_machine.change_state(
		PlayerState.State.HURT,
		hurt_data
	)
# ==============================================================================
# 10. 命中有效性
# ==============================================================================
func _can_receive_hit(incoming: HitBox) -> bool:
	if incoming.hit_info == null:
		return false
	if incoming.source is not Player:
		return false
	var source := incoming.source as Player
	if source == self:
		return false
	if source.team_id == team_id:
		return false
	match incoming.hit_info.attack_type:
		Types.AttackType.KICK:
			return false
		Types.AttackType.SLIDE:
			return is_running()
	return true
func is_running() -> bool:
	return state_machine.current_state.name == "Run"
# ==============================================================================
# 11. 受击结果结算
# ==============================================================================
func _resolve_hurt_data(
	source: Player,
	hit_info: HitInfo
) -> HurtData:
	match hit_info.attack_type:
		Types.AttackType.SLIDE:
			return _create_normal_hurt_data(
				hit_info.attack_direction
			)
	if source.endurance + 8 >= endurance:
		return _create_hurt_data(
			hit_info,
			Types.HurtType.HEAVY
		)
	return _create_normal_hurt_data(
		hit_info.attack_direction
	)
# ==============================================================================
# 12. HurtData 创建
# ==============================================================================
func _create_hurt_data(
	hit_info: HitInfo,
	hurt_type: Types.HurtType
) -> HurtData:
	var hurt_data := HurtData.new()
	hurt_data.hurt_type = hurt_type
	hurt_data.knockback_direction = (
		_calculate_knockback_direction(
			hit_info.attack_direction,
			input_component.last_move_direction
		)
	)
	hurt_data.knockback_speed = (
		hit_info.knockback_speed
	)
	hurt_data.z_velocity = (
		hit_info.z_velocity
	)
	return hurt_data
func _create_normal_hurt_data(
	knockback_direction: Vector2
) -> HurtData:
	var hurt_data := HurtData.new()
	hurt_data.hurt_type = Types.HurtType.NORMAL
	hurt_data.knockback_direction = knockback_direction
	hurt_data.knockback_speed = 6.0
	return hurt_data
# ==============================================================================
# 13. 击退方向
# ==============================================================================
func _calculate_knockback_direction(
	attack_direction: Vector2,
	last_move_direction: Vector2
) -> Vector2:
	if (
		last_move_direction.x != 0.0
		and last_move_direction.y != 0.0
	):
		var same_horizontal_direction := (
			last_move_direction.x * attack_direction.x > 0.0
		)
		return (
			last_move_direction
			if same_horizontal_direction
			else -last_move_direction
		)
	if last_move_direction.x != 0.0:
		return attack_direction
	if last_move_direction.y != 0.0:
		return (
			Vector2.UP
			if attack_direction.x > 0.0
			else Vector2.DOWN
		)
	return attack_direction
