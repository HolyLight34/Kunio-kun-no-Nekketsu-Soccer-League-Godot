class_name Player
extends CharacterBody2D


# ==============================================================================
# 1. 配置
# ==============================================================================

@export var team_id: Types.Team
@export var player_id: int = 1

@export_group("Components")
@export var input_component: InputComponent
@export var state_machine: StateMachine

@export var endurance: int:
	set(value):
		endurance = max(0, value)

		if is_inside_tree() and has_node("Label"):
			$Label.text = str(endurance)


# ==============================================================================
# 2. 常量
# ==============================================================================

const COLLISION_HEIGHT: int = 32

## 当前角色所属队伍的进攻方向。
@export var team_attack_direction: Types.TeamAttackDirection = Types.TeamAttackDirection.RIGHT


func get_team_attack_direction() -> Types.TeamAttackDirection:
	return team_attack_direction
# ==============================================================================
# 3. 节点引用
# ==============================================================================

@onready var player_intent_resolver: PlayerIntentResolver = (
	$Components/PlayerIntentResolver
)

@onready var player_horizontal_movement: PlayerHorizontalMovement = (
	$Components/PlayerHorizontalMovement
)

@onready var player_z_movement: PlayerZMovement = (
	$Components/PlayerZMovement
)

@onready var step_animation_component: StepAnimationComponent = (
	$Components/StepAnimationComponent
)
@onready var facing_root: Node2D = $FacingRoot

@onready var entity_position_visual_component: EntityPositionVisualComponent = $Components/EntityPositionVisualComponent

@onready var ball_contact_detector: HitBox = $FacingRoot/BallContactDetector

@onready var endurance_label: Label = $Label

@onready var pass_target_detector: PassTargetDetector = $PassTargetDetector

#@onready var ball_receiver_area: BallReceiverArea = $InteractionRoot/BallReceiverArea

@onready var player_composite_sprite: PlayerCompositeSprite = $Visual/PlayerCompositeSprite
@onready var ball_contact_handler: BallContactHandler = $Components/BallContactHandler
@onready var player_contact_handler: PlayerContactHandler = $Components/PlayerContactHandler
@onready var player_contact_detector: HitBox = $FacingRoot/PlayerContactDetector

# ==============================================================================
# 4. 运行状态
# ==============================================================================

var ball: Ball

var ball_possession: Types.BallPossession

var is_stomping_ball: bool = false

var facing_direction := Vector2.LEFT:
	set(value):
		if facing_direction == value:
			return

		facing_direction = value


# ==============================================================================
# 5. 生命周期 / 初始化
# ==============================================================================

func _ready() -> void:
	_initialize_components()

	endurance_label.text = str(endurance)


func _initialize_components() -> void:
	player_horizontal_movement.set_horizontal_position(
		position
	)

	player_intent_resolver.init(
		self,
		input_component
	)
	ball_contact_handler.initialize(self)
	ball_contact_detector.contact_started.connect(
		ball_contact_handler._on_contact_started
	)
	ball_contact_detector.contact_ended.connect(
		ball_contact_handler._on_contact_ended
	)
	player_contact_handler.initialize(self)
	player_contact_detector.contact_started.connect(
		player_contact_handler._on_contact_started
	)
	player_contact_detector.contact_ended.connect(
		player_contact_handler._on_contact_ended
	)
	state_machine.init(self)

func _physics_process(delta: float) -> void:
	var intent: PlayerIntentResolver.Intent = (
		player_intent_resolver.get_intent()
	)
	state_machine.handle_intent(
		intent,
		delta
	)

	_update_pass_search_direction()


# ==============================================================================
# 6. Logic Tick
# ==============================================================================

func logic_tick() -> void:
	state_machine.physics_tick()
	player_z_movement.logic_tick()
	step_animation_component.advance_tick()
	_update_facing(
		input_component.move_dir.x
	)
	player_horizontal_movement.step_logic_tick()
	entity_position_visual_component.set_shadow_visible(is_in_air())
	ball_contact_detector.logic_tick()
	player_contact_detector.logic_tick()
	ball_contact_handler.logic_tick()
	player_contact_handler.logic_tick()
	entity_position_visual_component.update_position(
		get_logical_position(),
		get_z_height()
	)



# ==============================================================================
# 7. 基础查询
# ==============================================================================

func get_logical_position() -> Vector2:
	return player_horizontal_movement.get_horizontal_position()


func get_z_height() -> float:
	return player_z_movement.get_z_height()


func get_z_velocity() -> float:
	return player_z_movement.get_z_velocity()
func get_player_velocity() -> Vector3:
	return Vector3(
		get_horizontal_velocity().x,
		get_horizontal_velocity().y,
		get_z_velocity()
	)
func get_player_position() -> Vector3:
	return Vector3(
		get_logical_position().x,
		get_logical_position().y,
		get_z_height()
	)

func get_horizontal_velocity() -> Vector2:
	return player_horizontal_movement.get_horizontal_velocity()

func get_horizontal_position_integer() -> Vector2:
	return player_horizontal_movement.get_horizontal_position_integer()
func get_z_height_integer() -> int:
	return player_z_movement.get_z_height_integer()
func get_z_velocity_integer() -> int:
	return player_z_movement.get_z_velocity()

func is_in_air() -> bool:
	return player_z_movement.is_in_air


func is_moving() -> bool:
	return (
		player_horizontal_movement.get_horizontal_velocity()
			!= Vector2.ZERO
		or
		player_z_movement.get_z_velocity() != 0.0
	)


func is_running() -> bool:
	return state_machine.current_state.name == "Run"


# ==============================================================================
# 8. 朝向
# ==============================================================================

func get_facing_direction() -> Vector2:
	return facing_direction
func _update_facing(
	move_input_x: float
) -> void:
	if move_input_x == 0.0:
		return

	var current_state := (
		state_machine.current_state as EntityState
	)

	if current_state == null:
		return

	if (
		current_state.facing_mode
		== PlayerState.FacingMode.LOCK
	):
		return

	var new_facing := (
		Vector2.RIGHT
		if move_input_x > 0.0
		else Vector2.LEFT
	)

	set_facing_direction(new_facing)
func _update_facing_root() -> void:
	if facing_direction.x < 0:
		facing_root.scale.x = 1.0

	elif facing_direction.x > 0:
		facing_root.scale.x = -1.0
func set_facing_direction(new_facing: Vector2) -> void:
	if new_facing == facing_direction:
		return

	facing_direction = new_facing

	# 更新视觉朝向
	entity_position_visual_component.set_facing_direction(
		facing_direction
	)

	# 更新方向相关检测区域
	_update_facing_root()
## 角色接球时面向足球。
func _face_ball() -> void:
	var player_x := FixedPoint.to_integer(
		get_logical_position().x
	)

	var ball_x := FixedPoint.to_integer(
		ball.get_logical_position().x
	)

	if ball_x < player_x:
		set_facing_direction(Vector2.LEFT)

	elif ball_x > player_x:
		set_facing_direction(Vector2.RIGHT)


# ==============================================================================
# 10. 球权
# ==============================================================================

func _on_ball_possession_changed(
	new_carrier: Player
) -> void:
	if new_carrier == null:
		ball_possession = (
			Types.BallPossession.NONE
		)

	elif new_carrier == self:
		ball_possession = (
			Types.BallPossession.MYSELF
		)

	elif new_carrier.team_id == team_id:
		ball_possession = (
			Types.BallPossession.TEAMMATE
		)

	else:
		ball_possession = (
			Types.BallPossession.OPPONENT
		)


func release_ball() -> void:
	if ball == null:
		return

	if ball.carrier != self:
		return

	ball.release_from_carrier()


# ==============================================================================
# 11. 足球接触
# ==============================================================================

# ==============================================================================
# 12. 足球 Shot 控制
# ==============================================================================

func _process_ball_control() -> void:
	if ball == null:
		return

	if not ball.can_receive_y_control():
		return

	var move_direction := (
		input_component.get_move_direction()
	)

	ball.apply_y_control(
		signi(int(move_direction.y))
	)


# ==============================================================================
# 13. 传球目标搜索
# ==============================================================================

func _update_pass_search_direction() -> void:

	if input_component.move_dir != Vector2.ZERO:
		pass_target_detector.set_search_direction(
			input_component.move_dir
		)
	else:
		pass_target_detector.set_search_direction(
			facing_direction
		)
	


func open_ball_action_window(action: Types.BallContactAction) -> void:
	ball_contact_handler.open_action_window(action)

func close_ball_action_window() -> void:
	ball_contact_handler.close_action_window()

func open_player_contact_window(action: Types.PlayerContactAction) -> void:
	player_contact_handler.open_action_window(action)

func close_player_contact_window() -> void:
	player_contact_handler.close_action_window()
	

# ==============================================================================
# 17. Strike 处理
# ==============================================================================
func resolve_tackle(
	data: TackleData
) -> void:
	## 铲球只有在目标正在跑动时，
	## 才会对角色产生受伤效果。
	if not is_running():
		return
	release_ball()
	state_machine.change_state(
		PlayerState.State.REBOUND,
		data.attack_direction
	)
func resolve_strike(
	data: StrikeData
) -> void:
	release_ball()

	# 普通角色攻击受伤规则。
	if data.endurance + 8 >= endurance:
		state_machine.change_state(
			PlayerState.State.KNOCKBACK,
			data.attack_direction
		)

	else:
		state_machine.change_state(
			PlayerState.State.REBOUND,
			data.attack_direction
		)

		data.attacker.receive_rebound()

	endurance -= data.damage
	
# ==============================================================================
# Ball_Attack 处理
# ==============================================================================
func _resolve_ball_attack(
	data: BallAttackData
) -> void:
	endurance -= data.damage
	state_machine.change_state(
			PlayerState.State.KNOCKBACK,
			data.attack_direction
		)
# ==============================================================================
# 18. 外部受伤结果接口
# ==============================================================================

## 让当前角色执行反弹。
##
## 反弹方向由角色自身当前朝向决定，
## 调用方不需要知道具体反弹方向规则。
func receive_rebound() -> void:
	release_ball()

	state_machine.change_state(
		PlayerState.State.REBOUND,
		-facing_direction
	)
