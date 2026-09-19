extends Node
class_name Match


@export var ball: Ball
@onready var player: Player = $Player

var ball_carrier: Player = null

var team1: Array[Player] = []
var team2: Array[Player] = []


func _ready() -> void:
	_collect_teams()
	_setup_players()

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
