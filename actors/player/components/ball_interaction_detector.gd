extends Area2D
class_name BallInteractionDetector


@export var player: Player


signal chest_trap_requested(ball: Ball)
signal pickup_requested(ball: Ball)


# 当前位于交互范围内的足球
var ball_in_range: Ball = null

# 自己刚释放出去的球。
# 在它离开当前检测范围之前，暂时忽略交互。
var ignored_ball: Ball = null


func check_ball_interaction() -> void:
	if ball_in_range == null:
		return

	# 自己刚释放的球，在离开范围之前不允许再次交互。
	if ball_in_range == ignored_ball:
		return

	# 优先判断胸停。
	if _can_chest_trap(ball_in_range):
		chest_trap_requested.emit(ball_in_range)
		return

	# 再判断普通拾球。
	if _can_pickup_ball(ball_in_range):
		pickup_requested.emit(ball_in_range)


# ------------------------------------------------------------------------------
# 交互规则
# ------------------------------------------------------------------------------

func _can_chest_trap(ball: Ball) -> bool:
	# 已经被某个角色持有，不允许胸停。
	if ball.carrier != null:
		return false

	# 胸停只处理空中的球。
	if not ball.is_in_air():
		return false

	var ball_position := ball.get_logical_position()
	var player_position := player.get_logical_position()

	# FC 的 Z 高度范围判断：
	#
	# ball_z < player_z + 32
	# player_z < ball_z + 16
	#
	# 等价于：
	# -16 < ball_z - player_z < 32
	return (
		ball_position.z < player_position.z + 32.0
		and player_position.z < ball_position.z + 16.0
	)


func _can_pickup_ball(ball: Ball) -> bool:
	# 已经被某个角色持有，不允许再次拾取。
	if ball.carrier != null:
		return false

	# 普通拾球只处理地面上的球。
	if ball.is_in_air():
		return false

	return true


# ------------------------------------------------------------------------------
# 临时忽略自己刚释放的球
# ------------------------------------------------------------------------------

func ignore_ball_until_exit(ball: Ball) -> void:
	ignored_ball = ball


func clear_ignored_ball() -> void:
	ignored_ball = null


# ------------------------------------------------------------------------------
# Area2D 信号
# ------------------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if body is not Ball:
		return

	var ball := body as Ball

	ball_in_range = ball

	print(
		"BALL ENTER: ",
		ball,
		" ignored=",
		ball == ignored_ball
	)


func _on_body_exited(body: Node2D) -> void:
	if body is not Ball:
		return

	var ball := body as Ball

	print("BALL EXIT: ", ball)

	# 如果是自己刚释放的球，
	# 直到它真正离开交互范围以后才解除忽略。
	if ball == ignored_ball:
		ignored_ball = null

	# 清除当前范围内的球。
	if ball == ball_in_range:
		ball_in_range = null
