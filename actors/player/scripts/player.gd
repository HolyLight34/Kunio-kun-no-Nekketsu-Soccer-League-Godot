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

@onready var entity_position_visual_component: EntityPositionVisualComponent = $Components/EntityPositionVisualComponent

@onready var visual: Node2D = $Visual
@onready var colliders: Node2D = $Colliders
@onready var hit_box: HitBox = $Colliders/HitBox

@onready var endurance_label: Label = $Label

@onready var pass_target_detector: PassTargetDetector = (
	$PassTargetDetector
)

@onready var ball_receiver_area: BallReceiverArea = (
	$BallReceiverArea
)

@onready var player_composite_sprite: PlayerCompositeSprite = $Visual/PlayerCompositeSprite

# ==============================================================================
# 4. 运行状态
# ==============================================================================

var ball: Ball

var ball_possession: Types.BallPossession



var facing_direction := Vector2.LEFT:
	set(value):
		if facing_direction == value:
			return

		facing_direction = value

		pass_target_detector.set_search_direction(
			facing_direction
		)


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

	step_animation_component.advance_tick()

	player_z_movement.logic_tick()

	_update_facing(
		input_component.move_dir.x
	)
	player_horizontal_movement.step_logic_tick()
	entity_position_visual_component.set_shadow_visible(is_in_air())
	_process_ball_contact()
	_process_ball_control()
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


func get_horizontal_velocity() -> Vector2:
	return player_horizontal_movement.get_horizontal_velocity()


func get_collision_height() -> int:
	return COLLISION_HEIGHT


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

	if new_facing == facing_direction:
		return

	facing_direction = new_facing
	entity_position_visual_component.set_facing_direction(facing_direction)


## 角色接球自动转向
func _face_ball() -> void:
	var player_x := FixedPoint.to_integer(
		get_logical_position().x
	)

	var ball_x := FixedPoint.to_integer(
		ball.get_logical_position().x
	)

	if ball_x < player_x:
		entity_position_visual_component.set_facing_direction(
			Vector2.LEFT
		)

	elif ball_x > player_x:
		entity_position_visual_component.set_facing_direction(
			Vector2.RIGHT
		)


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

func _process_ball_contact() -> void:
	if ball == null:
		return

	if not ball.can_be_received():
		return

	if ball.get_receiver() != self:
		return

	# 地面球。
	if not ball.is_in_air():
		ball.receive_ground_pickup(self)
		return

	# 原地挑球特殊限制。
	if (
		ball.is_stationary_flick_active()
		and
		not is_moving()
	):
		return

	# 接到空中球时面向足球。
	_face_ball()

	# 空中接球。
	if is_in_air():
		ball.receive_air_control(self)
		return
	if is_running():
		if ball.is_in_air():
			ball.receive_juggle(self)
			state_machine.change_state(
				PlayerState.State.JUGGLE
			)
		return
	# 地面胸停。
	state_machine.change_state(
		PlayerState.State.CHEST_TRAP
	)

	ball.receive_air_control(self)


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
	if (
		ball_possession
		!= Types.BallPossession.MYSELF
	):
		return

	if input_component.move_dir != Vector2.ZERO:
		pass_target_detector.set_search_direction(
			input_component.move_dir
		)
	else:
		pass_target_detector.set_search_direction(
			facing_direction
		)


# ==============================================================================
# 14. HitBox 公共接口
# ==============================================================================

## 准备踢球命中数据。
func prepare_kick_hit(
	kick_type: KickData.KickType
) -> void:
	_prepare_hit(
		Types.HitType.KICK,
		_create_kick_data(kick_type)
	)


## 准备传球命中数据。
func prepare_pass_hit() -> void:
	_prepare_hit(
		Types.HitType.PASS,
		_create_pass_data()
	)


## 准备角色攻击命中数据。
func prepare_strike_hit(
	attack_type: Types.AttackType,
	damage: int
) -> void:
	_prepare_hit(
		Types.HitType.STRIKE,
		_create_strike_data(
			attack_type,
			damage
		)
	)


## 开启命中判定窗口。
func enable_hit() -> void:
	hit_box.enabled = true


## 关闭命中判定窗口。
func disable_hit() -> void:
	hit_box.enabled = false


# ==============================================================================
# 15. Hit 数据创建
# ==============================================================================

func _prepare_hit(
	type: Types.HitType,
	payload: Variant
) -> void:
	var hit_info := HitInfo.new()

	hit_info.type = type
	hit_info.payload = payload

	hit_box.set_hit_info(hit_info)


func _create_kick_data(
	kick_type: KickData.KickType
) -> KickData:
	var data := KickData.new()

	data.kick_type = kick_type
	data.direction = facing_direction
	data.endurance = endurance

	return data


func _create_pass_data() -> PassData:
	var target := (
		pass_target_detector.find_best_target()
	)

	if target != null:
		return PassData.from_position(
			target.get_logical_position()
		)

	return PassData.from_offset(
		pass_target_detector
			.get_default_target_offset()
	)


func _create_strike_data(
	attack_type: Types.AttackType,
	damage: int
) -> StrikeData:
	var data := StrikeData.new()

	data.attacker = self
	data.attack_type = attack_type
	data.attack_direction = facing_direction
	data.endurance = endurance
	data.damage = damage

	return data


# ==============================================================================
# 16. HurtBox 受击入口
# ==============================================================================

func _on_hurt_box_hit_received(
	hit_info: HitInfo
) -> void:
	_resolve_hit(hit_info)


func _resolve_hit(
	hit_info: HitInfo
) -> void:
	match hit_info.type:
		Types.HitType.STRIKE:
			_resolve_strike(
				hit_info.payload
			)
		Types.HitType.BALL_ATTACK:
			_resolve_ball_attack(hit_info.payload)


# ==============================================================================
# 17. Strike 处理
# ==============================================================================

func _resolve_strike(
	data: StrikeData
) -> void:
	# 铲球只有在目标正在跑动时，
	# 才会对角色产生受伤效果。
	if (
		data.attack_type
			== Types.AttackType.SLIDE
		and
		not is_running()
	):
		return

	# 从这里开始已经确定角色受伤。
	# 所有受伤都会失去球权。
	release_ball()

	# 跑动中被铲球：
	# 直接进入 REBOUND。
	if (
		data.attack_type
		== Types.AttackType.SLIDE
	):
		state_machine.change_state(
			PlayerState.State.REBOUND,
			data.attack_direction
		)
		return

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
