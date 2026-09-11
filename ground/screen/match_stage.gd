# res://scenes/match_stage/match_stage.gd
extends Node
class_name MatchStage

@export var ball: Ball

 #=====================================================================
 #1. 初始化阶段：组装全场
 #=====================================================================
var team1: Array[Player]
var team2: Array[Player]
func _ready() -> void:
	# 🌟 核心：把足球登记给全局球权总管，让大管家开始监听足球信号
	if MatchManager:
		MatchManager.register_ball(ball)
	for player in get_children():
		if player is Player:
			if player.team_id == MatchManager.Team.PLAYER_TEAM:
				team1.append(player)
				player.pass_target_detector.teammates = team1
			else :
				team2.append(player)
				player.pass_target_detector.teammates = team2
	
		pass
	
