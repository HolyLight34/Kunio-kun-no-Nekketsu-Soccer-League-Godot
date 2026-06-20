# FC_Camera.gd
extends Camera2D

@export var ball_path: NodePath

var ball: Ball = null


func _ready() -> void:
	if ball_path: ball = get_node(ball_path) as Ball


# 🎯 改回 _physics_process，并且绝对不执行任何 lerp 缓冲！
func _physics_process(_delta: float) -> void:
	if not ball: return

	# 零延迟强行同步坐标
	if ball.carrier != null:
		global_position = ball.carrier.global_position
	else:
		global_position = ball.global_position
