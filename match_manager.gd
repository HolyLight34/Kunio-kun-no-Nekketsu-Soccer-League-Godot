# res://global/match_manager.gd
extends Node

# 场上唯一的足球引用
var current_ball: Ball = null
# res://global/match_manager.gd 内部
enum Team {
	PLAYER_TEAM,   # 我方阵营（热血高校）
	ENEMY_TEAM,    # 敌方阵营（日本队/海外强队）       # 中立阵营（比如裁判、或者是乱入的第三方，留作扩展）
}
enum BallPossession {
	NONE,          # 0: 无主自由球（大家快来抢）
	MYSELF,        # 1: 真正意义上的【我自己持球】
	MY_TEAMMATE,   # 2: 【我方队友持球】（我可以去跑位、问他要球）
	ENEMY_TEAM     # 3: 【敌方持球】（危险！快去铲他）
}
# 🎯 当前真正抓着球的球员节点（如果没人持球，则为 null）
var ball_carrier: Player = null


## 游戏初始化时，由关卡把球引用塞进来，并顺手绑好信号
func register_ball(ball_node: Ball) -> void:
	current_ball = ball_node
	
	# 🌟 总管在后台偷偷监听足球抛出的核心信号
	current_ball.possession_changed.connect(_on_ball_possession_changed)
	current_ball.possession_lost.connect(_on_ball_possession_lost)
## 🎯 统一收拢：处理抢球逻辑
func _on_ball_possession_changed(new_carrier: Node) -> void:
	# 1. 稳健防护：先把上一个持球人的状态解脱掉
	#if ball_carrier and is_instance_valid(ball_carrier):
		#ball_carrier.is_holding_ball = false
	
	# 2. 更新总管自己的账本
	ball_carrier = new_carrier
	
	# 3. 统一给新持球人赋能
	#if ball_carrier and is_instance_valid(ball_carrier):
		#ball_carrier.is_holding_ball = true
		
	print("📢 [球权总管]: 球被 ", ball_carrier.name, " 抢走了！全场局势已动态刷新。")

## 🎯 统一收拢：处理丢球/踢球逻辑
func _on_ball_possession_lost() -> void:
	#if ball_carrier and is_instance_valid(ball_carrier):
		#ball_carrier.is_holding_ball = false
		
	ball_carrier = null
	print("📢 [球权总管]: 球飞出了或处于无主状态！")
## 🌟 核心：供所有球员和 AI 查询的快捷函数
func get_possession_for(actor: Node) -> BallPossession:
	# 1. 安全防护
	if ball_carrier == null or not is_instance_valid(ball_carrier):
		return BallPossession.NONE
		
	# 2. 精准一刀：拿着球的人就是 actor 本人！
	if ball_carrier == actor:
		return BallPossession.MYSELF
		
	# 3. 类型防崩
	if not "team_id" in actor or not "team_id" in ball_carrier:
		return BallPossession.NONE
		
	# 4. 判断是不是队友
	if ball_carrier.team_id == actor.team_id:
		return BallPossession.MY_TEAMMATE # 是队友持球
	else:
		return BallPossession.ENEMY_TEAM  # 是敌人持球
