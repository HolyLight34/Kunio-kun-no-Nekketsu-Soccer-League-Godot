
class_name BallPlayerContactHandler
extends Node


# ==============================================================================
# 依赖与接触状态
# ==============================================================================

## 负责组装本组件的角色。
var ball: Ball

var _target_player: Player = null


# ==============================================================================
# 初始化
# ==============================================================================

## 由 Player 统一初始化。
func initialize(owner_ball: Ball) -> void:
	ball = owner_ball


# ==============================================================================
# 接触状态
# ==============================================================================

## 由 Player 的 HitBox 信号连接调用。
func _on_contact_started(target: Node) -> void:
	if target is not Player:
		return

	_target_player = target as Player
	
func _on_contact_ended(target: Node) -> void:
	if target != _target_player:
		return

	_target_player = null


# ==============================================================================
# 逻辑步
# ==============================================================================

## 由统一逻辑步调度器调用。
##
## 接触持续期间反复尝试处理。
## 条件不满足时等待；成功响应后不重复执行。
func logic_tick() -> void:
	if _target_player == null:
		return
	_handle_contact()


# ==============================================================================
# 足球接触处理
# ==============================================================================
func _handle_contact() -> void:
	if ball.carrier:
		return
	if ball.state_machine.is_in_state(BallState.State.SHOT):
		_target_player.resolve_strike(_create_strike_data(5))
		return
	if ball.stationary_flick_active:
		if _target_player.state_machine.is_in_state(PlayerState.State.RUN):
			ball.receive_juggle(_target_player)
			return
		if _target_player.is_moving():
			ball.receive_air_control(_target_player)
			if _target_player.get_z_height_integer() == 0:
				ball.receive_air_control(_target_player)
				_target_player.state_machine.change_state(PlayerState.State.CHEST_TRAP)
		return
	if ball.get_z_height_integer() == 0 and !ball.ball_z_movement.is_rising():
		ball.receive_ground_pickup(_target_player)
		return
	if ball.is_in_air() and _target_player.get_z_height_integer() == 0:
		ball.receive_air_control(_target_player)
		_target_player.state_machine.change_state(PlayerState.State.CHEST_TRAP)
	pass
func _create_strike_data(
	damage: int
) -> StrikeData:
	var data := StrikeData.new()

	data.attacker = ball.carrier
	data.attack_direction = Vector2.RIGHT
	data.endurance = 255
	data.damage = damage

	return data
