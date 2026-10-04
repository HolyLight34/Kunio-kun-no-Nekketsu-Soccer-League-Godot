extends Node
class_name SoccerMatch


@export var ball: Ball
@onready var player: Player = $Player
@onready var fc_logic_clock: FCLogicClock = $FCLogicClock

var ball_carrier: Player = null

var team1: Array[Player] = []
var team2: Array[Player] = []
func _on_logic_tick() -> void:
	for child in get_children():
		if child is Player:
			var current_player := child as Player
			current_player.logic_tick()

	ball.logic_tick()

func _ready() -> void:
	fc_logic_clock.logic_tick.connect(_on_logic_tick)
	_collect_teams()
	_setup_players()

func _collect_teams() -> void:
	for child in get_children():
		if not child is Player:
			continue

		var player := child as Player
		player.ball = ball
		ball.possession_changed.connect(player._on_ball_possession_changed)
		if player.team_id == Types.Team.TEAM_1:
			team1.append(player)
		else:
			team2.append(player)


func _setup_players() -> void:
	
	for player: Player in team1:
		player.pass_target_detector.teammates = team1

	for player: Player in team2:
		player.pass_target_detector.teammates = team2
