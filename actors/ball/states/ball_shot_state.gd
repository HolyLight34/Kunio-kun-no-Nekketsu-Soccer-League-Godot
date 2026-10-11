
extends BallState


## =============================================================================
## BallShotState
##
## 负责执行射门计算结果：
## - 初始化足球运动
## - 设置攻击判定
## - 控制无重力阶段
## - 处理高空射门落地后的运动
##
## FC 参数由 BallActionCalculator 计算。
## =============================================================================


## 临时测试阈值。
## 后续应从比赛难度配置获取。
const TEST_HEIGHT_THRESHOLD: int = 28

## 每次进入或退出状态时更新，防止旧 await 继续执行。
var _execution_id: int = 0


func enter(data: KickData) -> void:
	_execution_id += 1
	var current_execution: int = _execution_id

	# ================================================================
	# 1. 计算射门参数
	# ================================================================

	var result: BallShotResult = ball.action_calculator.calculate_shot(
		ball.get_logical_position(),
		ball.get_z_height(),
		data,
		TEST_HEIGHT_THRESHOLD
	)

	if not result.is_valid:
		push_warning("BallShotState: 射门计算结果无效")
		change_state(State.FREE)
		return

	# 保存本次射门需要的数据。
	var attack_direction: Vector2 = data.direction

	# ================================================================
	# 2. 初始化 Z 轴
	# ================================================================

	ball.ball_z_movement.gravity_disable()

	ball.ball_z_movement.set_z_height(
		result.initial_z_height
	)

	ball.ball_z_movement.launch(
		result.z_velocity
	)

	# ================================================================
	# 3. 初始化水平运动
	# ================================================================

	ball.ball_horizontal_movement.set_horizontal_position(
		result.initial_position
	)

	ball.ball_horizontal_movement.set_horizontal_velocity(
		result.horizontal_velocity
	)

	# ================================================================
	# 4. 初始化动画和攻击判定
	# ================================================================

	if result.height_category == BallShotResult.ShotHeightCategory.HIGH_AIR:
		anim.play(anim_name)

	ball.enable_hit()

	ball.prepare_ball_attack_hit(
		attack_direction,
		result.power,
		5
	)

	# ================================================================
	# 5. 无重力持续阶段
	# ================================================================


	ball.tick_timer_component.start_timer(
		"shot",
		result.duration_ticks
	)

	await ball.tick_timer_component.timer_finished

	if not _is_execution_valid(current_execution):
		return

	ball.ball_z_movement.gravity_enable()

	# ================================================================
	# 6. 高空射门落地处理
	# ================================================================

	if result.height_category == BallShotResult.ShotHeightCategory.HIGH_AIR:
		await ball.ball_z_movement.landed

		if not _is_execution_valid(current_execution):
			return

		ball.ball_horizontal_movement.set_horizontal_velocity(
			result.horizontal_velocity * 2.0
		)

		ball.ball_z_movement.launch(4)

		# 暂时保留原来的高空射门后续状态行为。
		return

	change_state(State.FREE)


func physics_tick() -> void:
	#print("Z=", ball.get_z_height()," VZ=", ball.ball_z_movement.z_velocity_raw," gravity=", ball.ball_z_movement._gravity_enabled)
	pass


func exit() -> void:
	_execution_id += 1

	ball.disable_hit()
	ball.ball_z_movement.gravity_enable()


## 判断当前异步执行是否仍然有效。
func _is_execution_valid(execution_id: int) -> bool:
	return (
		is_inside_tree()
		and execution_id == _execution_id
	)
