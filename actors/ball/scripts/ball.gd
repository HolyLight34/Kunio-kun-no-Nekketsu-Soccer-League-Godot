class_name Ball
extends CharacterBody2D
# ==============================================================================
# 1. 信号
# ==============================================================================
signal possession_changed(new_carrier: Player)
signal possession_lost
# ==============================================================================
# 2. 节点引用
# ==============================================================================
@onready var state_machine: StateMachine = $StateMachine
@onready var tick_component: TickComponent = $TickComponent
@onready var tick_timer_component: TickTimerComponent = $TickTimerComponent
@onready var ball_horizontal_component: BallHorizontalComponent = (
	$BallHorizontalComponent
)
@onready var ball_z_movement: BallZMovement = $BallZMovement
@onready var step_animation_component: StepAnimationComponent = (
	$StepAnimationComponent
)
@onready var entity_visual_controller: EntityVisualController = (
	$EntityVisualController
)
# ==============================================================================
# 3. 运行状态
# ==============================================================================
var carrier: Player = null
# ==============================================================================
# 4. 生命周期
# ==============================================================================
func _ready() -> void:
	state_machine.init(self)
	tick_component.tick_triggered.connect(_on_logic_tick)
	ball_z_movement.landed.connect(
		ball_horizontal_component.apply_landing_decay
	)
	ball_z_movement.finished.connect(
		ball_horizontal_component.roll
	)
# ==============================================================================
# 5. Logic Tick
# ==============================================================================
func _on_logic_tick() -> void:
	state_machine.physics_tick()
	ball_z_movement.process_z_step()
	ball_horizontal_component.step_logic_tick()
	step_animation_component.advance_tick()
	Log.debug(
		Log.Cat.PHYSICS,
		"物理帧：%d" % Engine.get_physics_frames()
	)
# ==============================================================================
# 6. 球权
# ==============================================================================
func can_be_picked_up() -> bool:
	return carrier == null
func set_carried_by(new_carrier: Player) -> void:
	if carrier == new_carrier:
		return
	# 清理旧持球者
	if carrier != null:
		carrier.carried_ball = null
	# 建立新的双向关系
	carrier = new_carrier
	new_carrier.carried_ball = self
	state_machine.change_state(
		BallState.State.HOLD
	)
	possession_changed.emit(new_carrier)
func release_from_carrier() -> void:
	if carrier == null:
		return
	var old_carrier := carrier
	carrier = null
	old_carrier.carried_ball = null
	state_machine.change_state(
		BallState.State.FREE
	)
	possession_lost.emit()
# ==============================================================================
# 7. 外部交互接口
# ==============================================================================
func receive_kick(hit_info: HitInfo) -> void:
	release_from_carrier()
	state_machine.change_state(
		BallState.State.SHOT,
		hit_info
	)
# ==============================================================================
# 8. HurtBox 回调
# ==============================================================================
func _on_hurt_box_hit_received(incoming: HitBox) -> void:
	if incoming.hit_info == null:
		return
	match incoming.hit_info.attack_type:
		Types.AttackType.KICK:
			_receive_kick_hit(incoming)
		Types.AttackType.SLIDE:
			_receive_slide_hit(incoming)
func _receive_kick_hit(incoming: HitBox) -> void:
	receive_kick(incoming.hit_info)

func _receive_slide_hit(incoming: HitBox) -> void:
	if incoming.source is not Player:
		return
	set_carried_by(incoming.source)
