class_name PlayerIntentResolver
extends Node


## PlayerIntentResolver
##
## 负责把玩家输入解析为基础游戏意图。
##
## 本组件可以根据球权关系解释 A / B 的基础含义，例如：
##
##     自己持球 + B -> KICK
##     自己持球 + A -> PASS
##     队友持球 + B -> COMMAND_SHOOT
##     对手持球 + A -> TACKLE
##
## 但不负责解析依赖当前 Player State 的特殊动作，例如：
##
##     Jump + 反方向 + KICK -> BICYCLE_KICK
##     Run + 特定输入        -> ELBOW_DIVE
##     Run + 反方向          -> BRAKE
##
## 这些规则由对应 State 根据基础 Intent 继续解释。


# ============================================================
# 玩家基础意图
# ============================================================

enum Intent {
	IDLE,
	WALK,
	RUN,
	JUMP,

	KICK,
	PASS,

	COMMAND_PASS,
	COMMAND_SHOOT,

	ELBOW_STRIKE,
	TACKLE,
}


# ============================================================
# 外部依赖
# ============================================================

var player: Player
var input_component: InputComponent


func init(
	source: Player,
	input_node: InputComponent,
) -> void:
	player = source
	input_component = input_node


# ============================================================
# 双击方向检测
# ============================================================

@onready var double_tap_timer: Timer = $Timer

var last_tapped_direction: StringName = &""


# ============================================================
# A / B 输入缓冲
#
# A 与 B 可能不是在同一个 Physics Frame 被检测到，
# 因此第一次检测到按钮后，短暂等待另一个按钮。
#
# A + B -> JUMP
# ============================================================

const MAX_BUTTON_BUFFER_FRAMES: int = 2

var is_buffering_buttons: bool = false
var button_buffer_frames: int = 0

var buffered_a_pressed: bool = false
var buffered_b_pressed: bool = false


# ============================================================
# 主入口
# ============================================================

func get_intent() -> Intent:
	# --------------------------------------------------------
	# 1. 双击方向
	# --------------------------------------------------------

	var double_tap_intent := _resolve_double_tap()

	if double_tap_intent != Intent.IDLE:
		return double_tap_intent


	# --------------------------------------------------------
	# 2. 捕捉 A / B
	# --------------------------------------------------------

	_collect_action_buttons()


	# --------------------------------------------------------
	# 3. 处理 A / B 缓冲
	# --------------------------------------------------------

	if is_buffering_buttons:
		return _resolve_buffered_buttons()


	# --------------------------------------------------------
	# 4. 普通移动
	# --------------------------------------------------------

	if input_component.move_dir != Vector2.ZERO:
		return Intent.WALK


	# --------------------------------------------------------
	# 5. 无输入
	# --------------------------------------------------------

	return Intent.IDLE


# ============================================================
# 双击方向
# ============================================================

func _resolve_double_tap() -> Intent:
	var current_direction: StringName = &""

	if input_component.dir_left_just:
		current_direction = &"left"

	elif input_component.dir_right_just:
		current_direction = &"right"

	elif input_component.dir_up_just:
		current_direction = &"up"

	elif input_component.dir_down_just:
		current_direction = &"down"


	if current_direction == &"":
		return Intent.IDLE


	# 第二次点击同一个方向，并且仍处于双击时间窗口内。
	if (
		not double_tap_timer.is_stopped()
		and current_direction == last_tapped_direction
	):
		double_tap_timer.stop()
		last_tapped_direction = &""

		return Intent.RUN


	# 第一次点击。
	last_tapped_direction = current_direction
	double_tap_timer.start()

	return Intent.IDLE


# ============================================================
# 捕捉动作键
# ============================================================

func _collect_action_buttons() -> void:
	if (
		not input_component.btn_a_just
		and not input_component.btn_b_just
	):
		return


	if not is_buffering_buttons:
		is_buffering_buttons = true
		button_buffer_frames = 0


	if input_component.btn_a_just:
		buffered_a_pressed = true


	if input_component.btn_b_just:
		buffered_b_pressed = true


# ============================================================
# 处理 A / B 输入缓冲
# ============================================================

func _resolve_buffered_buttons() -> Intent:
	# 缓冲期间继续捕捉 A / B。
	if input_component.btn_a:
		buffered_a_pressed = true

	if input_component.btn_b:
		buffered_b_pressed = true


	# --------------------------------------------------------
	# A + B
	# --------------------------------------------------------

	if buffered_a_pressed and buffered_b_pressed:
		return _finish_button_buffer(Intent.JUMP)


	# --------------------------------------------------------
	# 等待另一个按钮
	# --------------------------------------------------------

	button_buffer_frames += 1

	if button_buffer_frames < MAX_BUTTON_BUFFER_FRAMES:
		# 输入缓冲期间仍然允许角色继续移动。
		if input_component.move_dir != Vector2.ZERO:
			return Intent.WALK

		return Intent.IDLE


	# --------------------------------------------------------
	# 缓冲结束，解析单键意图
	# --------------------------------------------------------

	var intent := _resolve_single_button_intent()

	return _finish_button_buffer(intent)


# ============================================================
# 单键动作解析
#
# A / B 的基础含义由当前球权关系决定。
#
# 注意：
# 这里只解析所有状态共用的基础意图。
#
# 不在这里判断：
# - 当前是否 Jump
# - 当前是否 Run
# - 是否输入反方向
# - 是否应该倒钩
# - 是否应该飞肘
# - 是否应该刹车
#
# 这些属于具体 State 的动作规则。
# ============================================================

func _resolve_single_button_intent() -> Intent:
	match player.ball_possession:

		# ----------------------------------------------------
		# 自己持球
		#
		# B -> 踢球
		# A -> 传球
		# ----------------------------------------------------

		Types.BallPossession.MYSELF:
			if buffered_b_pressed:
				return Intent.KICK

			if buffered_a_pressed:
				return Intent.PASS


		# ----------------------------------------------------
		# 队友持球
		#
		# B -> 命令射门
		# A -> 命令传球
		# ----------------------------------------------------

		Types.BallPossession.TEAMMATE:
			if buffered_b_pressed:
				return Intent.COMMAND_SHOOT

			if buffered_a_pressed:
				return Intent.COMMAND_PASS


		# ----------------------------------------------------
		# 对手持球
		#
		# B -> 肘击
		# A -> 铲球
		# ----------------------------------------------------

		Types.BallPossession.OPPONENT:
			if buffered_b_pressed:
				return Intent.ELBOW_STRIKE

			if buffered_a_pressed:
				return Intent.TACKLE


		# ----------------------------------------------------
		# 无人持球
		#
		# 目前继续解析为基础 KICK / PASS。
		#
		# 是否进一步变成倒钩、飞肘等特殊动作，
		# 交给当前 State 判断。
		# ----------------------------------------------------

		Types.BallPossession.NONE:
			if buffered_b_pressed:
				return Intent.KICK

			if buffered_a_pressed:
				return Intent.PASS


	return Intent.IDLE


# ============================================================
# 完成按钮缓冲
# ============================================================

func _finish_button_buffer(result: Intent) -> Intent:
	is_buffering_buttons = false
	button_buffer_frames = 0

	buffered_a_pressed = false
	buffered_b_pressed = false

	return result
