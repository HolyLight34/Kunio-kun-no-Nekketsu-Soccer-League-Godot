# res://scenes/match_stage/match_stage.gd
extends Node
class_name MatchStage

# 🛠️ 导演需要指挥的片场道具（子节点引用）
#@onready var ball: GameBall = $Ball
#@onready var camera: Camera2D = $Camera2D
#@onready var ui_manager: Node = $MatchUI # 假设你的UI总管节点

# 🏃 导演需要指挥的演员（首发位置标记点，可以在场景里拖拽放好 Marker2D）
#@onready var p1_spawn_point: Marker2D = $SpawnPoints/P1Spawn
#@onready var p2_spawn_point: Marker2D = $SpawnPoints/P2Spawn
#@onready var enemy_spawn_points: Node2D = $SpawnPoints/EnemySpawns
@onready var ball: Ball = $Ball

# 🎬 状态变量：当前比赛阶段
#enum MatchPhase { PRE_GAME, PLAYING, GOAL_CELEBRATION, POST_GAME }
#var current_phase: MatchPhase = MatchPhase.PRE_GAME

# =====================================================================
# 1. 初始化阶段：组装全场
# =====================================================================
func _ready() -> void:
	# 🌟 核心：把足球登记给全局球权总管，让大管家开始监听足球信号
	if MatchManager:
		MatchManager.register_ball(ball)
	
	# 🌟 注册大导演自己要听的全局大喇叭信号
	#GlobalSignals.goal_scored.connect(_on_goal_scored)
	#GlobalSignals.match_time_up.connect(_on_match_time_up)
	
	# 开启开场流程
	#_start_pre_game_flow()

# =====================================================================
# 2. 比赛流程控制（导演的喊话）
# =====================================================================
#
### 🎬 流程 A：开场准备（Ready... Go!）
#func _start_pre_game_flow() -> void:
	#current_phase = MatchPhase.PRE_GAME
	#
	## 1. 所有人回到开球初始位置，并锁死状态机（不让乱跑）
	#_reset_all_entities_to_spawn()
	#_freeze_all_players(true)
	#
	## 2. 通知 UI 播放经典的街机开场动画（比如闪烁的 "READY" ➔ "GO!"）
	## ui_manager.play_ready_go_animation()
	#
	## 3. 产生一个原打法中延时：等待 2 秒动画播完，正式开哨！
	#await get_tree().create_timer(2.0).timeout
	#_start_match_playing()
#
### ⚽ 流程 B：正式开球（比赛进行中）
#func _start_match_playing() -> void:
	#current_phase = MatchPhase.PLAYING
	#
	## 1. 解锁全场球员的状态机，大家可以自由移动、肘击、抢球了！
	#_freeze_all_players(false)
	#
	## 2. 激活计时器（让比分板的倒计时开始走）
	## ScoreManager.start_countdown()
	#print("📢 [大导演]: 哨响！比赛正式开始！")
#
### 🥅 流程 C：进球后的清理与重置
#func _on_goal_scored(team_id: int) -> void:
	## 防呆：如果已经进入进球庆祝阶段，不重复触发
	#if current_phase == MatchPhase.GOAL_CELEBRATION: return
	#current_phase = MatchPhase.GOAL_CELEBRATION
	#
	#print("📢 [大导演]: 进球有效！全场特写开始，准备重置球场。")
	#
	## 1. 强行静止全场球员（切到 Idle 状态并加锁，只播放庆祝或者抱头痛哭的动画）
	#_freeze_all_players(true)
	## 可以在这里让进球者强行切到 "Celebrate" 状态
	#
	## 2. 留出 3 秒钟给镜头特写、UI 进球特效表演、或者放进球音乐
	#await get_tree().create_timer(3.0).timeout
	#
	## 3. 检查比赛是否真的结束（比如是不是绝杀了，或者时间到了）
	## if ScoreManager.is_match_over(): return
	#
	## 4. 如果比赛继续，重新进入开场准备，交换球权或中圈开球
	#_start_pre_game_flow()
#
### ⏱️ 流程 D：终场哨响
#func _on_match_time_up() -> void:
	#current_phase = MatchPhase.POST_GAME
	#_freeze_all_players(true)
	#
	## 播放长哨音效，UI 弹出结算面板
	#print("📢 [大导演]: 哔——哔——哔——！全场比赛结束！")
	## ui_manager.show_settlement_screen()
#
## =====================================================================
## 3. 导演的底层控制手腕（辅助工具函数）
## =====================================================================
#
### 🥶 让全场所有人（P1/P2/AI）原地冻结或解冻
#func _freeze_all_players(should_freeze: bool) -> void:
	## 通过 Godot 的群组（Group）机能，一句话抓出全场所有的球员
	## （记得在 Player 和 AI 的场景根节点里，把它们加入 "players" 群组）
	#var all_players = get_tree().get_nodes_in_group("players")
	#
	#for player in all_players:
		#if player.has_node("StateMachine"):
			#var sm = player.get_node("StateMachine")
			#if should_freeze:
				## 强行锁死大脑，切换到 Idle，不读任何按键输入
				#sm.change_state("Idle")
				#sm.is_locked = true
				#player.velocity = Vector2.ZERO
			#else:
				## 解锁大脑，让状态机恢复自由运转
				#sm.is_locked = false
#
### 🔄 把足球和所有人瞬移回出生点
#func _reset_all_entities_to_spawn() -> void:
	## 1. 足球回归正中央
	#ball.reparent(self) # 确保球从持球人身上拔下来，还给世界
	#ball.global_position = global_position # 假设 MatchStage 居中
	#if ball.state_machine:
		#ball.state_machine.change_state("Loose") # 球回归无主普通状态
	#
	## 2. 找到 P1 球员，瞬移到开球左侧点
	#var p1 = get_node_or_null("Player1")
	#if p1: p1.global_position = p1_spawn_point.global_position
	#
	## 3. 找到 P2 或 AI 队友，移到对应点...
	## ... 遍历重置位置 ...
