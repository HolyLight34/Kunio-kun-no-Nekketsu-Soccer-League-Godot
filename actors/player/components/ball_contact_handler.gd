
class_name BallContactHandler
extends Node


# ==============================================================================
# 依赖与接触状态
# ==============================================================================

## 负责组装本组件的角色。
var player: Player

var _target_ball: Ball = null



# ==============================================================================
# 初始化
# ==============================================================================

## 由 Player 统一初始化。
func initialize(owner_player: Player) -> void:
	player = owner_player


# ==============================================================================
# 接触状态
# ==============================================================================

## 由 Player 的 HitBox 信号连接调用。
func _on_contact_started(target: Node) -> void:
	if target is not Ball:
		return

	_target_ball = target as Ball

var _action_window_active: bool = false
var current_action: Types.BallContactAction


func open_action_window(action: Types.BallContactAction) -> void:
	current_action = action
	_action_window_active = true


func close_action_window() -> void:
	_action_window_active = false
func _on_contact_ended(target: Node) -> void:
	if target != _target_ball:
		return

	_target_ball = null


# ==============================================================================
# 逻辑步
# ==============================================================================

## 由统一逻辑步调度器调用。
##
## 接触持续期间反复尝试处理。
## 条件不满足时等待；成功响应后不重复执行。
func logic_tick() -> void:
	if _target_ball == null:
		return
	if _action_window_active:
		match current_action:
			Types.BallContactAction.KICK:
				_try_kick_ball()
			Types.BallContactAction.PASS:
				_try_pass_ball()
			Types.BallContactAction.SLIDE_TACKLE:
				_target_ball.resolve_tackle(player)
		return
	_process_ball_contact()


# ==============================================================================
# 足球接触处理
# ==============================================================================
func _try_kick_ball() -> void:
	_target_ball.resolve_kick(_create_kick_data())
	pass
func _try_pass_ball() -> void:
	_target_ball.resolve_pass(_create_pass_data())
	pass
func _process_ball_contact() -> void:
	if not _target_ball.can_be_received():
		return

	match _target_ball.get_receive_type():
		Ball.ReceiveType.NONE:
			return

		Ball.ReceiveType.BALL_HIT:
			#_response_handled = true

			player.state_machine.change_state(
				PlayerState.State.KNOCKBACK,
				-player.facing_direction
			)
			return

		Ball.ReceiveType.GROUND_PICKUP:
			if player.get_z_velocity() < 0:
				player.is_stomping_ball = true
				player.player_z_movement.set_rest_height(13)
				player.state_machine.change_state(PlayerState.State.LAND)
				player.ball.receive_stomped(player)
			else :
				player.ball.receive_ground_pickup(player)
			return

		Ball.ReceiveType.STATIONARY_FLICK:
			# 原地挑球特殊阶段：
			# 角色静止时不能接，
			# 移动时继续按照空中球处理。
			if not player.is_moving():
				return

		Ball.ReceiveType.AIR_CONTROL:
			pass

	# 能执行到这里的足球，
	# 都按照空中接球流程处理。

	player._face_ball()

	# 角色自身在空中：空中控球。
	if player.is_in_air():
		#_response_handled = true
		_target_ball.receive_air_control(player)
		return

	# 跑动中接到空中球：颠球。
	if player.is_running():
		#_response_handled = true

		_target_ball.receive_juggle(player)

		player.state_machine.change_state(
			PlayerState.State.JUGGLE
		)
		return

	# 站在地面接到空中球：胸停。
	#_response_handled = true

	player.state_machine.change_state(
		PlayerState.State.CHEST_TRAP
	)

	_target_ball.receive_air_control(player)
func _create_ball_data() -> BallData:
	var data := BallData.new()
	data.attack_direction = player.input_component.move_dir

	return data

func _create_kick_data() -> KickData:
	var data := KickData.new()
	data.direction = player.facing_direction
	data.endurance = player.endurance

	return data
func _create_pass_data() -> PassData:
	var target := (
		player.pass_target_detector.find_best_target()
	)

	if target != null:
		return PassData.from_position(
			target.get_logical_position()
		)

	return PassData.from_offset(
		player.pass_target_detector
			.get_default_target_offset()
	)
