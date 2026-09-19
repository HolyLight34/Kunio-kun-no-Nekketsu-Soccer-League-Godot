class_name Player
extends CharacterBody2D
# ==============================================================================
# 1. 配置
# ==============================================================================
@export var team_id: Types.Team
@export var player_id: int = 1
var ball: Ball
@export_group("Components")
@export var input_component: InputComponent
@export var state_machine: StateMachine
@export var endurance: int:
	set(value):
		endurance = max(0, value)

		if is_inside_tree() and has_node("Label"):
			$Label.text = str(endurance)
# ==============================================================================
# 2. 节点引用
# ==============================================================================
@onready var player_intent_resolver: PlayerIntentResolver = $Components/PlayerIntentResolver
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
@onready var colliders: Node2D = $Colliders
@onready var hit_box: HitBox = $Colliders/HitBox
@onready var ball_anchor: Marker2D = $Colliders/BallAnchor
@onready var endurance_label: Label = $Label
@onready var pass_target_detector: PassTargetDetector = $PassTargetDetector
@onready var attack_resolver: AttackResolver = $Components/AttackResolver
@onready var ball_interaction_detector: BallInteractionDetector = $Colliders/BallInteractionDetector

# ==============================================================================
# 3. 运行状态
# ==============================================================================
var facing_direction: Vector2 = Vector2.RIGHT
var ball_possession: Types.BallPossession
func _on_ball_possession_changed(new_carrier: Player) -> void:
	if new_carrier == null:
		ball_possession = Types.BallPossession.NONE

	elif new_carrier == self:
		ball_possession = Types.BallPossession.MYSELF

	elif new_carrier.team_id == team_id:
		ball_possession = Types.BallPossession.TEAMMATE

	else:
		ball_possession = Types.BallPossession.OPPONENT
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
	ball_interaction_detector.chest_trap_requested.connect(_on_chest_trap_requested)
	ball_interaction_detector.pickup_requested.connect(_on_pickup_requested)
func get_logical_position() -> Vector3:
	var horizontal_position := (
		player_horizontal_movement.get_horizontal_position()
	)
	return Vector3(
		horizontal_position.x,
		horizontal_position.y,
		player_z_movement.get_z_height()
	)

func _physics_process(delta: float) -> void:
	var intent: PlayerIntentResolver.Intent = (
		player_intent_resolver.get_intent()
	)
	state_machine.handle_intent(intent, delta)
	if ball_possession == Types.BallPossession.MYSELF:
		if input_component.move_dir != Vector2.ZERO:
			pass_target_detector.set_search_direction(input_component.move_dir)
		else :
			pass_target_detector.set_search_direction(facing_direction)
# ==============================================================================
# 5. 初始化
# ==============================================================================
func _initialize_components() -> void:
	player_horizontal_movement.set_horizontal_position(position)
	player_intent_resolver.init(self,input_component)
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
	ball_interaction_detector.check_ball_interaction()
	

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
func release_ball() -> void:
	if ball == null:
		return
	if ball.carrier != self:
		return
	ball.release_from_carrier()
func _on_chest_trap_requested(ball: Ball) -> void:
	ball.carrier = self
	face_position(ball.get_logical_horizontal_position())
	ball.ball_z_movement.launch(0.5)
	state_machine.change_state(PlayerState.State.CHEST_TRAP)
	# 处理胸部停球请求
	pass
func set_facing_direction(direction: Vector2):
	facing_direction = direction
	_apply_facing()
	pass
func face_position(target_position: Vector2) -> void:
	var direction := target_position - global_position
	if direction.x < 0.0:
		set_facing_direction(Vector2.LEFT)
	elif direction.x > 0.0:
		set_facing_direction(Vector2.RIGHT)
func get_z_height() -> float:
	return player_z_movement.get_z_height()
func _on_pickup_requested(ball: Ball) -> void:
	if not ball.can_be_picked_up():
		return
	face_position(ball.get_logical_horizontal_position())
	ball.set_carried_by(self)
	# 处理拾球请求
	pass
# ==============================================================================
# 9. 受击入口
# ==============================================================================
func receive_hurt(hurt_data: HurtData) -> void:
	endurance -= hurt_data.damage

	release_ball()

	state_machine.change_state(
		PlayerState.State.HURT,
		hurt_data
	)
func is_running() -> bool:
	return state_machine.current_state.name == "Run"

func _on_hit_box_target_detected(hurt_box: HurtBox,hit_info:HitInfo) -> void:
	attack_resolver.resolve_hit(hurt_box,hit_box.hit_info)

func _on_hurt_box_hurt_received(hurt_data: HurtData) -> void:
	receive_hurt(hurt_data)
