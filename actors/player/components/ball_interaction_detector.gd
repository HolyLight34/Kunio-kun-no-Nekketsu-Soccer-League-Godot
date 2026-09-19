extends Area2D
class_name BallInteractionDetector


@export var player: Player

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

signal chest_trap_requested(ball: Ball)
signal pickup_requested(ball: Ball)


# 当前位于交互范围内的足球
var ball_in_range: Ball = null

# 自己刚释放出去的球。
# 在它离开当前检测范围之前，暂时忽略交互。

func require_ball_reentry() -> void:
	ball_in_range = null
func check_ball_interaction() -> void:
	
	if ball_in_range == null:
		return
	# 优先判断胸停。
	if _can_chest_trap(ball_in_range):
		chest_trap_requested.emit(ball_in_range)
		return

	# 再判断普通拾球。
	if _can_pickup_ball(ball_in_range):
		pickup_requested.emit(ball_in_range)
	ball_in_range = null

func _can_chest_trap(ball: Ball) -> bool:
	# 已经被某个角色持有，不允许胸停。
	if ball.carrier != null:
		return false
	if ball_in_range.control_locked:
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





# ------------------------------------------------------------------------------
# Area2D 信号
# ------------------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if body is not Ball:
		return
	var ball := body as Ball
	ball_in_range = ball


func _on_body_exited(body: Node2D) -> void:
	if body is not Ball:
		return

	var ball := body as Ball

	print("BALL EXIT: ", ball)

	# 清除当前范围内的球。
	if ball == ball_in_range:
		ball_in_range = null
