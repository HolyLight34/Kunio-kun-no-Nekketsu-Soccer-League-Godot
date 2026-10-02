class_name Ball
extends CharacterBody2D


# ==============================================================================
# 1. 信号
# ==============================================================================

signal possession_changed(new_carrier: Player)
 
# ==============================================================================
# 2. 常量
# ==============================================================================

const COLLISION_HEIGHT: int = 16
const LEFT_GOAL_TARGET := Vector2(64, 192)
const RIGHT_GOAL_TARGET := Vector2(832, 192)

# ==============================================================================
# 3. 节点引用
# ==============================================================================
@onready var sprite_2d: Sprite2D = $Visual/Sprite2D

@onready var hit_box: HitBox = $HitBox

@onready var state_machine: StateMachine = $StateMachine

@onready var tick_component: TickComponent = $Components/TickComponent
@onready var tick_timer_component: TickTimerComponent = $Components/TickTimerComponent

@onready var ball_horizontal_movement: BallHorizontalMovement = (
	$Components/BallHorizontalMovement
)

@onready var ball_z_movement: BallZMovement = (
	$Components/BallZMovement
)

@onready var step_animation_component: StepAnimationComponent = (
	$Components/StepAnimationComponent
)

@onready var entity_visual_controller: EntityVisualController = (
	$Components/EntityVisualController
)
@onready var ball_interactable_area: Area2D = $BallInteractableArea


# ==============================================================================
# 4. 运行状态
# ==============================================================================

#var power: float
## 原地挑球标志 
## 解决原地挑球会触发自己的胸部停球
var stationary_flick_active: bool = false
## 角色拾取候选数组
var _receiver_candidates: Array[Player] = []


var carrier: Player = null:
	set(value):
		if carrier == value:
			return

		carrier = value
		possession_changed.emit(carrier)


# ==============================================================================
# 5. 生命周期
# ==============================================================================

func _ready() -> void:
	#sprite_2d.material.set_shader_parameter(
		#"to_color",
		#Color.BLUE
	#)
	state_machine.init(self)

	tick_component.tick_triggered.connect(
		_on_logic_tick
	)

	ball_z_movement.landed.connect(
		ball_horizontal_movement.apply_landing_decay
	)

	ball_z_movement.finished.connect(
		ball_horizontal_movement.roll
	)


# ==============================================================================
# 6. Logic Tick
# ==============================================================================

func _on_logic_tick() -> void:
	state_machine.physics_tick()

	ball_z_movement.process_z_step()
	ball_horizontal_movement.step_logic_tick()

	step_animation_component.advance_tick()


# ==============================================================================
# 7. 基础状态查询
# ==============================================================================

func get_logical_position() -> Vector2:
	return ball_horizontal_movement.get_horizontal_position()

func get_goal_target_position(
	flight_direction: Vector2
) -> Vector2:
	if flight_direction.x < 0.0:
		return LEFT_GOAL_TARGET

	return RIGHT_GOAL_TARGET

func get_z_height() -> float:
	return ball_z_movement.get_z_height()


func get_collision_height() -> int:
	return COLLISION_HEIGHT


func is_in_air() -> bool:
	return ball_z_movement.is_in_air


func is_stationary_flick_active() -> bool:
	return stationary_flick_active


func can_be_received() -> bool:
	return carrier == null


# ==============================================================================
# 8. 球权
# ==============================================================================

func receive_ground_pickup(player: Player) -> void:
	carrier = player

	state_machine.change_state(
		BallState.State.GROUND_CARRY
	)


func receive_air_control(player: Player) -> void:
	carrier = player

	state_machine.change_state(
		BallState.State.AIR_CONTROL
	)


func release_from_carrier() -> void:
	if carrier == null:
		return

	carrier = null


# ==============================================================================
# 9. 接球候选
# ==============================================================================

## 将角色加入接球候选名单。
func register_receiver(player: Player) -> void:
	if player in _receiver_candidates:
		return

	_receiver_candidates.append(player)


## 将角色移出接球候选名单。
func unregister_receiver(player: Player) -> void:
	_receiver_candidates.erase(player)


## 返回第一个满足 XYZ 接触条件的角色。
func get_receiver() -> Player:
	for player in _receiver_candidates:
		if _is_z_overlapping(player):
			return player

	return null


## 判断足球与角色的 Z 高度范围是否重叠。
func _is_z_overlapping(player: Player) -> bool:
	var player_z := FixedPoint.to_integer(
		player.get_z_height()
	)

	var ball_z := FixedPoint.to_integer(
		get_z_height()
	)

	return (
		ball_z < player_z + player.get_collision_height()
		and
		player_z < ball_z + get_collision_height()
	)


# ==============================================================================
# 10. Shot 控制
# ==============================================================================

func can_receive_y_control() -> bool:
	return state_machine.current_state.name == "Shot"

## 让外部角色可以控制球的y运动
func apply_y_control(direction: int) -> void:
	if not can_receive_y_control():
		return

	ball_horizontal_movement.apply_air_steering(
		direction
	)


# ==============================================================================
# 11. 外部动作接口
# ==============================================================================
func set_receivable_detection_enabled(enabled: bool) -> void:
	ball_interactable_area.set_deferred("monitorable",enabled)
func receive_stationary_flick() -> void:
	stationary_flick_active = true

	ball_z_movement.launch(8)

	state_machine.change_state(
		BallState.State.FREE
	)

	release_from_carrier()


func receive_moving_flick(kicker: Player) -> void:
	release_from_carrier()

	ball_horizontal_movement.set_horizontal_velocity(
		2.25 * kicker.facing_direction
	)

	ball_z_movement.set_z_height(10)
	ball_z_movement.launch(9)


# ==============================================================================
# 12. HitBox 攻击接口
# ==============================================================================

func prepare_ball_attack_hit(
	attack_direction: Vector2,
	power: int,
	damage: int
) -> void:
	var data := _create_ball_attack_data(
		attack_direction,
		power,
		damage
	)

	_prepare_hit(
		Types.HitType.BALL_ATTACK,
		data
	)


func _create_ball_attack_data(
	attack_direction: Vector2,
	power: int,
	damage: int
) -> BallAttackData:
	var data := BallAttackData.new()

	data.attack_direction = attack_direction
	data.power = power
	data.damage = damage

	return data


func _prepare_hit(
	type: Types.HitType,
	payload: Variant
) -> void:
	var hit_info := HitInfo.new()

	hit_info.type = type
	hit_info.payload = payload

	hit_box.set_hit_info(hit_info)


# ==============================================================================
# 13. HurtBox 命中处理
# ==============================================================================

func _on_hurt_box_hit_received(
	hit_info: HitInfo
) -> void:
	_resolve_hit(hit_info)


func _resolve_hit(hit_info: HitInfo) -> void:
	match hit_info.type:
		Types.HitType.PASS:
			_resolve_pass(hit_info.payload)

		Types.HitType.KICK:
			_resolve_kick(hit_info.payload)

		Types.HitType.STRIKE:
			_resolve_strike(hit_info.payload)


# ==============================================================================
# 14. Kick 处理
# ==============================================================================

func _resolve_kick(data: KickData) -> void:
	release_from_carrier()

	state_machine.change_state(
		BallState.State.SHOT,data
	)


# ==============================================================================
# 15. Pass 处理
# ==============================================================================

func _resolve_pass(data: PassData) -> void:
	release_from_carrier()

	var target_position: Vector2

	match data.target_type:
		PassData.TargetType.POSITION:
			target_position = data.target_position

		PassData.TargetType.OFFSET:
			var ball_position_integer := (
				FixedPoint.vector_to_integer(
					get_logical_position()
				)
			)

			target_position = Vector2(
				ball_position_integer
				+ data.target_offset
			)

	var pass_velocity := (
		PassTrajectoryCalculator.calculate(
			get_logical_position(),
			get_z_height(),
			target_position
		)
	)

	_apply_horizontal_launch(
		Vector2(
			pass_velocity.x,
			pass_velocity.y
		)
	)

	ball_z_movement.launch(
		pass_velocity.z
	)

	state_machine.change_state(
		BallState.State.FREE
	)


# ==============================================================================
# 16. Strike 处理
# ==============================================================================

func _resolve_strike(data: StrikeData) -> void:
	match data.attack_type:
		Types.AttackType.SLIDE:
			carrier = data.attacker

		_:
			return


# ==============================================================================
# 17. 内部运动辅助
# ==============================================================================

func _apply_horizontal_launch(
	velocity: Vector2
) -> void:
	release_from_carrier()

	ball_horizontal_movement.set_horizontal_velocity(
		velocity
	)
