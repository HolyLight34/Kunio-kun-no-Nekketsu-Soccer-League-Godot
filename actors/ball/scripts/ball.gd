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
const PLAYER_CONTROL_Y_OFFSET := 1.0

# ==============================================================================
# 场地表面类型
# ==============================================================================


## 足球湿度等级。
enum Wetness {
	DRY,
	LIGHT_WET,
	HEAVY_WET,
}

## 轻度湿润阈值。
const LIGHT_WET_THRESHOLD: int = 0x40

## 重度湿润阈值。
const HEAVY_WET_THRESHOLD: int = 0x80

## 湿度累计最大值。
const MAX_WETNESS_VALUE: int = 0xFF
## 足球当前累计湿度。
##
## 在积水区域中，每个 FC 逻辑步增加 1。
## 离开积水区域后不会自动减少。
const LIGHT_WET_WHITE := Color8(236, 238, 236)
const LIGHT_WET_BLACK := Color8(0, 102, 120)
const LIGHT_WET_RED := Color8(56, 180, 204)

const HEAVY_WET_WHITE := Color8(160, 214, 228)
const HEAVY_WET_BLACK := Color8(0, 102, 120)
const HEAVY_WET_RED := Color8(56, 180, 204)
var _wetness_value: int = 0

var wetness: Wetness = Wetness.DRY:
	set(value):
		if wetness == value:
			return

		wetness = value
		_apply_wetness_shader()
# ==============================================================================
# 3. 节点引用
# ==============================================================================
@onready var ball_sprite: Sprite2D = $Visual/Sprite2D

@onready var hit_box: HitBox = $HitBox

@onready var state_machine: StateMachine = $StateMachine

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

@onready var entity_position_visual_component: EntityPositionVisualComponent = $Components/EntityPositionVisualComponent


@onready var ball_interactable_area: Area2D = $BallInteractableArea


# ==============================================================================
# 4. 运行状态
# ==============================================================================


## 角色拾取候选数组
var _receiver_candidates: Array[Player] = []

var _base_ground_type: Types.BaseGroundType = Types.BaseGroundType.NORMAL
var stationary_flick_active := false
enum GroundType {
	NORMAL,
	PUDDLE,
	SWAMP,
	SAND,
}

enum ReceiveType {
	NONE,
	GROUND_PICKUP,
	AIR_CONTROL,
	STATIONARY_FLICK,
}

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
	state_machine.init(self)
	ball_z_movement.landed.connect(
		ball_horizontal_movement.apply_landing_decay
	)
	ball_z_movement.finished.connect(
		ball_horizontal_movement.roll
	)
	#ball_z_movement.launch(8)
func _apply_wetness_shader() -> void:
	var material := ball_sprite.material as ShaderMaterial

	match wetness:
		Wetness.DRY:
			material.set_shader_parameter(
				"palette_enabled",
				false
			)

		Wetness.LIGHT_WET:
			material.set_shader_parameter(
				"palette_enabled",
				true
			)

			material.set_shader_parameter(
				"white_color",
				LIGHT_WET_WHITE
			)
			material.set_shader_parameter(
				"black_color",
				LIGHT_WET_BLACK
			)
			material.set_shader_parameter(
				"red_color",
				LIGHT_WET_RED
			)

		Wetness.HEAVY_WET:
			material.set_shader_parameter(
				"palette_enabled",
				true
			)

			material.set_shader_parameter(
				"white_color",
				HEAVY_WET_WHITE
			)
			material.set_shader_parameter(
				"black_color",
				HEAVY_WET_BLACK
			)
			material.set_shader_parameter(
				"red_color",
				HEAVY_WET_RED
			)
func _resolve_ground_type(
	ground_effect: Types.GroundEffect
) -> GroundType:
	match ground_effect:
		Types.GroundEffect.PUDDLE:
			return GroundType.PUDDLE

		Types.GroundEffect.SWAMP:
			return GroundType.SWAMP

	if _base_ground_type == Types.BaseGroundType.SAND:
		return GroundType.SAND

	return GroundType.NORMAL
# ==============================================================================
# 6. Logic Tick
# ==============================================================================

func logic_tick(ground_effect: Types.GroundEffect) -> void:
	state_machine.physics_tick()
	var ground_type := _resolve_ground_type(ground_effect)
	ball_z_movement.logic_tick(ground_type,wetness,carrier == null)
	ball_horizontal_movement.step_logic_tick()
	tick_timer_component.logic_tick()
	step_animation_component.advance_tick()
	entity_position_visual_component.update_position(
		get_logical_position(),
		get_z_height()
	)
	_update_visual()
	_update_wetness(ground_effect)

func set_base_ground_type(
	ground_type: Types.BaseGroundType
) -> void:
	_base_ground_type = ground_type
	
## 清除足球累计湿度。
##
## 仅在已确认会清除湿度的足球规则中调用。
func clear_wetness() -> void:
	_wetness_value = 0
	

## 根据足球当前所在的特殊地形更新湿度。
func _update_wetness(ground_effect: Types.GroundEffect) -> void:
	if ground_effect != Types.GroundEffect.PUDDLE:
		return

	_wetness_value = mini(
		_wetness_value + 1,
		MAX_WETNESS_VALUE
	)

	if _wetness_value >= HEAVY_WET_THRESHOLD:
		wetness = Wetness.HEAVY_WET
	elif _wetness_value >= LIGHT_WET_THRESHOLD:
		wetness = Wetness.LIGHT_WET
	else:
		wetness = Wetness.DRY

func get_receive_type() -> ReceiveType:
	# 原地挑球第一次落地前的特殊接球规则。
	if stationary_flick_active:
		return ReceiveType.STATIONARY_FLICK

	# 有整数高度：空中球。
	if is_in_air():
		return ReceiveType.AIR_CONTROL

	# 整数高度虽然还是 0，
	# 但足球正在向上运动，不能作为地面球拾取。
	if ball_z_movement.is_rising():
		return ReceiveType.NONE

	# 普通地面球。
	return ReceiveType.GROUND_PICKUP
# ==============================================================================
# 7. 基础状态查询
# ==============================================================================
func _update_visual() -> void:
	entity_position_visual_component.set_shadow_visible(
		is_in_air()
	)
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
	return ball_z_movement.is_in_air()



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
	
	
func receive_juggle(player: Player) -> void:
	carrier = player
	state_machine.change_state(
		BallState.State.JUGGLE
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
	release_from_carrier()
	
	ball_z_movement.launch(8)

	state_machine.change_state(
		BallState.State.FREE
	)
	
	


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


func _on_ball_z_movement_landed() -> void:
	if stationary_flick_active:
		stationary_flick_active = false
