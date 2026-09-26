class_name Ball
extends CharacterBody2D
# ==============================================================================
# 1. 信号
# ==============================================================================
signal possession_changed(new_carrier: Player)
# ==============================================================================
# 2. 节点引用
# ==============================================================================
@onready var hit_box: HitBox = $HitBox
@onready var state_machine: StateMachine = $StateMachine
@onready var tick_component: TickComponent = $Components/TickComponent
@onready var tick_timer_component: TickTimerComponent = $Components/TickTimerComponent
@onready var ball_horizontal_movement: BallHorizontalMovement = $Components/BallHorizontalMovement
@onready var ball_z_movement: BallZMovement = $Components/BallZMovement
@onready var step_animation_component: StepAnimationComponent = $Components/StepAnimationComponent
@onready var entity_visual_controller: EntityVisualController = $Components/EntityVisualController
@onready var pass_target_detector: PassTargetDetector = $PassTargetDetector
@onready var ball_collision: CollisionShape2D = $CollisionShape2D

const COLLISION_HEIGHT: int = 16
var power: float
var control_locked: bool = false
var stationary_flick_active: bool = false
# ==============================================================================
# 3. 运行状态
# ==============================================================================
var carrier: Player = null:
	set(value):
		if carrier == value:
			return
		carrier = value
		possession_changed.emit(carrier)

# ==============================================================================
# 4. 生命周期
# ==============================================================================
func get_logical_position() -> Vector2:
	return ball_horizontal_movement.get_horizontal_position()
func can_be_received() -> bool:
	return carrier == null
func _ready() -> void:
	state_machine.init(self)
	tick_component.tick_triggered.connect(_on_logic_tick)
	#ball_control_area.player_detected.connect(_on_player_detected)
	ball_z_movement.landed.connect(
		ball_horizontal_movement.apply_landing_decay
	)
	ball_z_movement.finished.connect(
		ball_horizontal_movement.roll
	)

# ==============================================================================
# 5. Logic Tick
# ==============================================================================
func _on_logic_tick() -> void:
	state_machine.physics_tick()
	ball_z_movement.process_z_step()
	ball_horizontal_movement.step_logic_tick()
	step_animation_component.advance_tick()
# ==============================================================================
# 6. 球权
# ==============================================================================
func is_stationary_flick_active() -> bool:
	return stationary_flick_active
func receive_ground_pickup(player: Player) -> void:
	carrier = player
	state_machine.change_state(
		BallState.State.GRIYND_CARRY
	)
var _receiver_candidates: Array[Player] = []


func register_receiver(player: Player) -> void:
	if player in _receiver_candidates:
		return

	_receiver_candidates.append(player)


func unregister_receiver(player: Player) -> void:
	_receiver_candidates.erase(player)


func get_receiver() -> Player:
	for player in _receiver_candidates:
		if _is_z_overlapping(player):
			return player

	return null
func _is_z_overlapping(player: Player) -> bool:
	var player_z := FixedPoint.to_integer(player.get_z_height())
	var ball_z := FixedPoint.to_integer(get_z_height())

	return (
		ball_z < player_z + player.get_collision_height()
		and
		player_z < ball_z + get_collision_height()
	)
func get_collision_height() -> int:
	return COLLISION_HEIGHT
func get_z_height() -> float:
	return ball_z_movement.get_z_height()
func receive_chest_control(player: Player) -> void:
	carrier = player
	state_machine.change_state(BallState.State.AIR_CONTORL)
	pass
func release_from_carrier() -> void:
	if carrier == null:
		return
	carrier = null
# ==============================================================================
# 7. 外部交互接口
# ==============================================================================
func is_in_air() -> bool:
	return ball_z_movement.is_in_air

func receive_kick(
	kick_direction: Vector2,
	kicker_endurance: float,
	control_provider: Callable
) -> void:
	release_from_carrier()
	if not is_in_air():
		ball_z_movement.set_z_height(8)
	ball_horizontal_movement.set_horizontal_velocity(
		kick_direction * 8
	)
	power = kicker_endurance + 15
	state_machine.change_state(BallState.State.SHOT,control_provider)
	pass
## 让足球向指定目标位置执行传球。
##
## target_position：
## 传球最终目标的逻辑 XY 位置。
##
## 足球根据自身当前位置和 Z 高度，
## 按 FC 规则计算并应用传球初始速度。
func receive_pass(
	target_position: Vector2
) -> void:
	release_from_carrier()

	var pass_velocity := PassTrajectoryCalculator.calculate(
		get_logical_position(),
		get_z_height(),
		target_position
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

func _apply_horizontal_launch(
	velocity: Vector2
) -> void:
	release_from_carrier()
	ball_horizontal_movement.set_horizontal_velocity(
		velocity
	)
# ==============================================================================
# 8. HurtBox 回调
# ==============================================================================

func receive_stationary_flick() -> void:
	stationary_flick_active = true 
	ball_z_movement.launch(8)
	state_machine.change_state(BallState.State.FREE)
	release_from_carrier()
	
func receive_moving_flick(kicker: Player) -> void:
	release_from_carrier()
	ball_horizontal_movement.set_horizontal_velocity(2.25* kicker.facing_direction)
	ball_z_movement.set_z_height(10)
	ball_z_movement.launch(9)
	
func _receive_slide_hit(incoming: HitBox) -> void:
	if incoming.source is not Player:
		return
	receive_ground_pickup(incoming.source)

func _on_hit_box_target_detected(hurt_box: HurtBox, hit_info: HitInfo) -> void:
	var hurt_data = HurtData.new()
	hurt_data.damage = hit_info.damage
	hurt_data.hurt_type = Types.HurtType.HEAVY
	hurt_data.knockback_direction = hit_info.attack_direction
	hurt_data.knockback_speed = hit_info.horizontal_speed
	hurt_data.z_velocity =hit_info.z_velocity
	hurt_box.receive_hurt(hurt_data)
	pass # Replace with function body.
