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
var current_kicker: Player
var power: float
var control_locked: bool = false
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
func get_logical_horizontal_position() -> Vector2:
	return ball_horizontal_movement.get_horizontal_position()
func get_logical_position() -> Vector3:
	var horizontal_position := (
		ball_horizontal_movement.get_horizontal_position()
	)

	return Vector3(
		horizontal_position.x,
		horizontal_position.y,
		ball_z_movement.get_z_height()
	)
func _ready() -> void:
	state_machine.init(self)
	tick_component.tick_triggered.connect(_on_logic_tick)
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
	Log.debug(
		Log.Cat.PHYSICS,
		"物理帧：%d" % Engine.get_physics_frames()
	)
# ==============================================================================
# 6. 球权
# ==============================================================================
func can_be_picked_up() -> bool:
	if state_machine.current_state.name == "Shot":
		return false
	return carrier == null
func set_carried_by(new_carrier: Player) -> void:
	if carrier == new_carrier:
		return
	# 建立新的双向关系
	carrier = new_carrier
	state_machine.change_state(
		BallState.State.GRIYND_CARRY
	)
func get_z_height() -> float:
	return ball_z_movement.get_z_height()
func receive_chest_control(player: Player) -> void:
	carrier = player
	state_machine.change_state(
		BallState.State.AIR_CONTORL
	)
	pass
func release_from_carrier() -> void:
	if carrier == null:
		return
	carrier = null
	state_machine.change_state(
		BallState.State.FREE
	)
# ==============================================================================
# 7. 外部交互接口
# ==============================================================================
func is_in_air() -> bool:
	return ball_z_movement.is_in_air
func receive_kick(
	source: Player,
	power: float,
	velocity: Vector3
) -> void:
	self.power = power
	carrier = null
	current_kicker = source
	_apply_horizontal_launch(
		Vector2(
			velocity.x,
			velocity.y
		)
	)

	# 射门：这里按你的射门规则设置高度
	ball_z_movement.set_z_height(
		velocity.z
	)

	state_machine.change_state(
		BallState.State.SHOT
	)


func receive_pass(
	source: Player,
	velocity: Vector3
) -> void:
	carrier = null
	_apply_horizontal_launch(
		Vector2(
			velocity.x,
			velocity.y
		)
	)

	# 传球：velocity.z 是初始上升速度
	ball_z_movement.launch(
		velocity.z
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
	control_locked = true 
	ball_z_movement.launch(8)
	release_from_carrier()
	
func receive_moving_flick(kicker: Player) -> void:
	release_from_carrier()
	ball_horizontal_movement.set_horizontal_velocity(2.25* kicker.facing_direction)
	ball_z_movement.set_z_height(10)
	ball_z_movement.launch(9)
	
func _receive_slide_hit(incoming: HitBox) -> void:
	if incoming.source is not Player:
		return
	set_carried_by(incoming.source)

func _on_hit_box_target_detected(hurt_box: HurtBox, hit_info: HitInfo) -> void:
	var hurt_data = HurtData.new()
	hurt_data.damage = hit_info.damage
	hurt_data.hurt_type = Types.HurtType.HEAVY
	hurt_data.knockback_direction = hit_info.attack_direction
	hurt_data.knockback_speed = hit_info.horizontal_speed
	hurt_data.z_velocity =hit_info.z_velocity
	hurt_box.receive_hurt(hurt_data)
	pass # Replace with function body.


func _on_ball_z_movement_landed() -> void:
	control_locked = false
	pass # Replace with function body.
