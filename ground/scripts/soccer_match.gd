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


@onready var ball: Ball = $Ball

@onready var fc_logic_clock: FCLogicClock = $FCLogicClock
@onready var field: Field = $GrassField
var ball_action_calculator := BallActionCalculator.new()
var team1: Array[Player] = []
var team2: Array[Player] = []
@onready var player: Player = $Player
@onready var fc_logic_debugger: Control = $CanvasLayer/FCLogicDebugger
const SELF_SHORTCUT_DISTANCE := 64 # 原版 $40 短路保护阈值
## 查询指定队伍里离球最近的角色（带当前控制玩家本人 < 64 短路保护）。
func get_nearest_player_to_ball(current_player: Player) -> Player:
	if current_player == null or ball == null:
		return null

	var target_pos: Vector2i
	if ball.carrier != null:
		if ball.carrier.team_id == current_player.team_id:
			return ball.carrier
		target_pos = ball.carrier.get_horizontal_position_integer()
	else:
		target_pos = ball.get_horizontal_position_integer()

	# 原版 < 64 ($40) 玩家本人短路保护
	if calc_distance_score(current_player.get_horizontal_position_integer(), target_pos) < SELF_SHORTCUT_DISTANCE:
		return current_player

	var team_players: Array[Player] = team1 if current_player.team_id == Types.Team.TEAM_1 else team2
	var nearest_player: Player = null
	var min_score: int = 256

	for player in team_players:
		var score := calc_distance_score(player.get_horizontal_position_integer(), target_pos)
		if score < min_score:
			min_score = score
			nearest_player = player

	return nearest_player


static func calc_distance_score(a_pos: Vector2i, b_pos: Vector2i) -> int:
	var dx: int = absi(b_pos.x - a_pos.x)
	var dy: int = absi(b_pos.y - a_pos.y)
	if dx > 255 or dy > 255:
		return 255
	var major: int = maxi(dx, dy)
	var minor: int = mini(dx, dy)
	var shift: int = ((major - minor) >> 5) + 1
	return mini(major + (major >> shift), 255)
func _ready() -> void:
	fc_logic_clock.logic_tick.connect(_on_logic_tick)
	ball.set_base_ground_type(field.get_ground_type())
	var field_data := field.create_ball_field_data()
	ball_action_calculator.setup(field_data)
	ball.action_calculator = ball_action_calculator
	_collect_teams()
	_setup_players()
	

func _physics_process(_delta: float) -> void:
	fc_logic_debugger.set_physics_data(
		player.get_player_position(),
		player.get_player_velocity(),
		ball.get_ball_position(),
		ball.get_ball_velocity()
	)
	pass
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
		current_player.soccer_match = self
		current_player.fc_logic_clock = fc_logic_clock
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
