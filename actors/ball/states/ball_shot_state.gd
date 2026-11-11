
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

var current_tick: int
var result: BallShotResult
const MAX_TICKS: int = 16
func enter(data: KickData) -> void:
	current_tick = 0
	ball.set_player_interaction_enabled(false)
	# ================================================================
	# 1. 计算射门参数
	# ================================================================

	result = ball.action_calculator.calculate_shot(
		ball.get_logical_position(),
		ball.get_z_height(),
		data,
		TEST_HEIGHT_THRESHOLD
	)

	if not result.is_valid:
		push_warning("BallShotState: 射门计算结果无效")
		request_state(State.FREE)
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
	


func logic_tick() -> void:
	current_tick += 1
	if current_tick == 2:
		ball.set_player_interaction_enabled(true)
	if current_tick > result.duration_ticks:

		ball.ball_z_movement.gravity_enable()

	# ================================================================
	# 6. 高空射门落地处理
	# ================================================================

		if result.height_category == BallShotResult.ShotHeightCategory.HIGH_AIR:
			await ball.ball_z_movement.landed

			ball.ball_horizontal_movement.set_horizontal_velocity(
			result.horizontal_velocity * 2.0
			)

			ball.ball_z_movement.launch(4)

		# 暂时保留原来的高空射门后续状态行为。
			return

		request_state(State.FREE)
	pass


func exit() -> void:
	ball.ball_z_movement.gravity_enable()
