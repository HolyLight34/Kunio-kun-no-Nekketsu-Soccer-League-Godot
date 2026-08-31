class_name IntentComponent
extends Node

# 定义意图枚举
enum Intent {
	IDLE,
	WALK,
	RUN,
	JUMP,
	KICK,
	SEND_PASS,
	ELBOW_DIVE,
	BICYCLE_KICK,
}

@export var input: InputComponent
@export var player: Player

var last_tapped_dir: StringName = ""

@onready var timer: Timer = $Timer

# ==========================================
# 🔥 为了解决 A+B 冲突新增的内部变量
# ==========================================
var is_collecting_buttons: bool = false
var button_wait_frames: int = 0
const MAX_WAIT_FRAMES: int = 2 # 缓冲 2 帧，约 0.03 秒

# 记录缓冲期内玩家摸过哪些键
var cached_a_just: bool = false
var cached_b_just: bool = false


func get_intent() -> Intent:
	# 1. 捕捉方向瞬按（保持你原有的逻辑不变）
	var current_just_dir: StringName = ""
	if input.dir_left_just: current_just_dir = &"left"
	elif input.dir_right_just: current_just_dir = &"right"
	elif input.dir_up_just: current_just_dir = &"up"
	elif input.dir_down_just: current_just_dir = &"down"

	# 双击逻辑
	if current_just_dir != &"":
		if not timer.is_stopped() and current_just_dir == last_tapped_dir:
			timer.stop()
			return Intent.RUN
		else:
			last_tapped_dir = current_just_dir
			timer.start()

	# =================================================================
	# 🔥 核心魔改：A/B 键输入缓冲池逻辑
	# =================================================================
	
	# 检查这一帧有没有任何一个动作键刚刚被按下
	if input.btn_a_just or input.btn_b_just:
		is_collecting_buttons = true
		button_wait_frames = 0
		# 只要在这个时期内被按过，就打上勾，死死记住
		if input.btn_a_just: cached_a_just = true
		if input.btn_b_just: cached_b_just = true

	# 如果处于“扣留观察期”
	if is_collecting_buttons:
		# 顺便检查一下长按或者后面补按的情况
		if input.btn_a: cached_a_just = true
		if input.btn_b: cached_b_just = true
		
		# 极速判定：如果在这一帧里，A 和 B 都被摸到了，不等了！直接跳！
		if cached_a_just and cached_b_just:
			return _flush_and_return(Intent.JUMP)
			
		# 递增帧数计数器
		button_wait_frames += 1
		
		# 2 帧的时间到了，玩家没有补齐另一个键，开始单键或者特殊技结算
		if button_wait_frames >= MAX_WAIT_FRAMES:
			var final_intent = Intent.IDLE
			
			# 判定：鱼跃/肘击 (横向 X轴移动且按了 B)
			if input.move_dir.x != 0 and input.move_dir.y == 0 and cached_b_just:
				final_intent = Intent.ELBOW_DIVE
			# 判定：纯 B (踢球)
			elif cached_b_just:
				final_intent = Intent.KICK
			# 判定：纯 A (传球)
			elif cached_a_just:
				final_intent = Intent.SEND_PASS
				
			return _flush_and_return(final_intent)
			
		# 如果还没满 2 帧，且还没凑齐 A+B，就让代码“憋住”，返回 IDLE 或者基础移动，不触发任何攻击
		else:
			if input.move_dir != Vector2.ZERO:
				return Intent.WALK
			return Intent.IDLE

	# =================================================================
	# 3. 基础移动（没有动作键按下时的普通走动）
	# =================================================================
	if input.move_dir != Vector2.ZERO:
		return Intent.WALK
		
	return Intent.IDLE


# 🔥 辅助函数：结算并清空缓冲池
func _flush_and_return(result_intent: Intent) -> Intent:
	is_collecting_buttons = false
	button_wait_frames = 0
	cached_a_just = false
	cached_b_just = false
	return result_intent
