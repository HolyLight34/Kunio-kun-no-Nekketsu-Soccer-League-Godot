extends Node2D
@onready var player: Player = $Player
@onready var ball: Ball = $Ball
func _ready() -> void:
	player.ball_fired.connect(ball.receive_kick)
	pass
