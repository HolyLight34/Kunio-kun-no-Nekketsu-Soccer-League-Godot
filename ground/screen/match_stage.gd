extends Node
class_name Match


@export var ball: Ball

var ball_carrier: Player = null

var team1: Array[Player] = []
var team2: Array[Player] = []


func _ready() -> void:
	_collect_teams()
	_setup_players()

	ball.possession_changed.connect(_on_ball_possession_changed)


func _collect_teams() -> void:
	for child in get_children():
		if not child is Player:
			continue

		var player := child as Player

		if player.team_id == Types.Team.TEAM_1:
			team1.append(player)
		else:
			team2.append(player)


func _setup_players() -> void:
	for player: Player in team1:
		player.pass_target_detector.teammates = team1

	for player: Player in team2:
		player.pass_target_detector.teammates = team2


func get_ball_carrier() -> Player:
	return ball_carrier


func _on_ball_possession_changed(new_carrier: Player) -> void:
	ball_carrier = new_carrier

	if ball_carrier == null:
		print("当前无人持球")
	else:
		print("球被 ", ball_carrier.name, " 获得")
