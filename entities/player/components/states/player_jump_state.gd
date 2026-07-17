extends PlayerState

const FC_JUMP_ABSOLUTE_TABLE: Array[int] = [
	0, # 序号0：前3帧离地 0 像素（还在地上蓄力）
	0, # 序号1：第4-6帧离地 0 像素（继续蓄力）
	4, # 序号2：第7-9帧离地 12 像素（猛地起飞！）
	7, # 序号3：第10-12帧离地 22 像素
	10, # 序号4：第13-15帧离地 29 像素（最高点）
	13, # 序号5：第16-18帧离地 22 像素（开始下落）
	15, # 序号6：第19-21帧离地 12 像素
	16,
	17,
	18, # 序号7：第22-24帧离地 0 像素（安全着陆）
	18,
	17,
	16,
	15,
	13,
	10,
	7,
	4,
	0,
	0,
	0,
	0,
	0,
	0,
]

var total_ticks: int = 0


func enter() -> void:
	total_ticks = 0
	player.animation_player.play("idle")
	pass


func exit() -> void:

	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	# 1. 核心算法：利用 3.0 浮点除法保留精度，再用 int() 截断，完美卡出 3帧一次的 FC 定格感！
	var table_index = int(total_ticks / 3.0)

	# 2. 如果账本还没读完，继续在空中飞
	if table_index < FC_JUMP_ABSOLUTE_TABLE.size():
		var z_height = FC_JUMP_ABSOLUTE_TABLE[table_index]

		# 把当前帧拿到的高度，暴力塞给大管家去刷新画面
		player.action_component.update_z_height(z_height)

		# 3. 【动画切片控制】：用绝对是整数的表索引来控衣服，100% 精准！
		if table_index == 2:
			# 对应原 6 帧：蓄力结束，离地刹那，切成空中空翻
			player.action_component.play_action("jump_up")
		elif table_index == 7:
			# 对应原 21 帧：到达或即将到达最高点
			player.action_component.play_action("jump_peak")
		elif table_index == 9:
			# 对应原 27 帧：开始急速下坠
			player.action_component.play_action("jump_down")
		elif table_index == 18:
			# 对应原 54 帧：落地死板僵直，完美还原热血足球
			print(z_height)
			player.action_component.play_action("jump_land")
		# 4. 横向物理：虽然人在天上，但影子和碰撞盒在地上依然可以被玩家操控横移
		#var input_dir = player.parser.get_movement_intent()
		#player.movement_component.apply_movement(input_dir, player.stats.speed)

		# 账本计数器雷打不动每帧 +1
		total_ticks += 1
	else:
		# 5. 账本读完了，执行落地
		land()
	pass

func land() -> void:
	player.action_component.update_z_height(0.0) # 确保高度完全归零
	#allow_facing_update = true     # 解锁转身限制
	
	# 抛出信号，让状态机把你切回 Idle 状态
	change_state(State.IDLE)
func handle_intent(_intent: int, _delta: float) -> void:
	#match intent:
		#IntentParser.Intent.IDLE:
			#change_state(State.IDLE)
	pass
