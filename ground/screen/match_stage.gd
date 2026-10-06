class_name SoccerMatch
extends Node


## SoccerMatch
##
## 一场足球比赛的主场景。
##
## 负责：
## - 组织比赛级对象。
## - 驱动 Player / Ball 的 FC 逻辑步。
## - 从 Field 获取场地信息，并提供给需要这些信息的实体。
## - 初始化球队相关依赖。
##
## 不负责：
## - Player 自身的行为规则。
## - Ball 自身的行为规则。
## - 判断特殊地形的具体范围。
## - 决定实体如何响应地形。


@export var ball: Ball

@onready var fc_logic_clock: FCLogicClock = $FCLogicClock
@onready var field: Field = $GrassField


var ball_carrier: Player = null

var team1: Array[Player] = []
var team2: Array[Player] = []


func _ready() -> void:
	fc_logic_clock.logic_tick.connect(_on_logic_tick)
	ball.set_base_ground_type(field.get_ground_type())
	_collect_teams()
	_setup_players()


func _on_logic_tick() -> void:
	for child in get_children():
		if child is Player:
			var current_player := child as Player
			current_player.logic_tick()

	var ball_ground_effect := field.get_ground_effect_at(
		ball.get_logical_position()
	)

	ball.logic_tick(ball_ground_effect)


func _collect_teams() -> void:
	for child in get_children():
		if not child is Player:
			continue

		var current_player := child as Player

		current_player.ball = ball
		ball.possession_changed.connect(
			current_player._on_ball_possession_changed
		)

		if current_player.team_id == Types.Team.TEAM_1:
			team1.append(current_player)
		else:
			team2.append(current_player)


func _setup_players() -> void:
	for current_player: Player in team1:
		current_player.pass_target_detector.teammates = team1

	for current_player: Player in team2:
		current_player.pass_target_detector.teammates = team2
