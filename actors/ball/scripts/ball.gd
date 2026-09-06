class_name Ball
extends CharacterBody2D

## 📡 信号：球权被某人夺取了
signal possession_changed(new_carrier: Node)
## 📡 信号：球脱离了控制（被踢飞、漏球、无主滚动）
signal possession_lost()
@onready var hit_box: HitBox = $HitBox
var carrier: Player = null

@onready var visual: Node2D = $Visual
@onready var step_animation_component: StepAnimationComponent = $StepAnimationComponent
@onready var ball_z_movement: BallZMovement = $BallZMovement
@onready var entity_visual_controller: EntityVisualController = $EntityVisualController
@onready var tick_timer_component: TickTimerComponent = $TickTimerComponent
func can_be_picked_up() -> bool:
	return carrier == null
func _ready() -> void:
	sm.init(self)
	tick_component.tick_triggered.connect(_on_3_tick)
	ball_z_movement.landed.connect(ball_horizontal_component.apply_landing_decay)
	ball_z_movement.finished.connect(ball_horizontal_component.roll)
	pass

func _on_3_tick() -> void:
	sm.physics_tick()
	ball_z_movement.process_z_step()
	ball_horizontal_component.step_logic_tick()
	step_animation_component.advance_tick()
	Log.debug(Log.Cat.PHYSICS,"物理帧：%d " % [Engine.get_physics_frames()])
func receive_kick(hit_info):
	sm.change_state(BallState.State.SHOT,hit_info)
	pass
# 被捡起时的切换接口
func set_carried_by(new_carrier: Player) -> void:
	print("设置足球携带状态")
	carrier = new_carrier
	sm.change_state(BallState.State.HOLD)

# 被踢出去或传出去时的释放接口
func release_from_carrier() -> void:
	carrier = null
	sm.change_state(BallState.State.FREE)
#region
@onready var sm: StateMachine = $StateMachine
@onready var tick_component: TickComponent = $TickComponent
@onready var ball_horizontal_component: BallHorizontalComponent = $BallHorizontalComponent

#endregion
func _on_hurt_box_hit_received(incoming: HitBox) -> void:
	print("踢")
	if incoming.hit_info.attack_type == Types.AttackType.KICK:
		sm.change_state(BallState.State.SHOT)
	#if incoming.hit_info.damage != 0:
		#sm.change_state(BallState.State.SHOT)
		#hit_box.hit_info = incoming.hit_info
	#else :
		#carrier = incoming.attacker
		#sm.change_state(BallState.State.HOLD)
	pass # Replace with function body.
