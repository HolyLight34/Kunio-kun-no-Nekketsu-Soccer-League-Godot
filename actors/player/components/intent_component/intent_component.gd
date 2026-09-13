class_name PlayerIntentResolver
extends Node


# ============================================================
# 玩家意图
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

	ELBOW_DIVE,
	ELBOW_STRIKE,
	TACKLE,
}


# ============================================================
# 当前球权与自己的关系
# ============================================================

enum BallPossession {
	NONE,       # 当前无人持球
	MYSELF,     # 自己持球
	TEAMMATE,   # 队友持球
	OPPONENT,   # 对手持球
}


# ============================================================
# 外部依赖
# ============================================================

var player: Player
var input_component: InputComponent
var match_context: Match


func init(
	player_node: Player,
	input_node: InputComponent,
	match_node: Match
) -> void:
	player = player_node
	input_component = input_node
	match_context = match_node


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
	# 缓冲期间继续检查按钮。
	if input_component.btn_a:
		buffered_a_pressed = true

	if input_component.btn_b:
		buffered_b_pressed = true


	# A + B
	if buffered_a_pressed and buffered_b_pressed:
		return _finish_button_buffer(Intent.JUMP)


	button_buffer_frames += 1


	# 仍处于等待窗口。
	if button_buffer_frames < MAX_BUTTON_BUFFER_FRAMES:
		if input_component.move_dir != Vector2.ZERO:
			return Intent.WALK

		return Intent.IDLE


	# 缓冲结束，结算单键动作。
	var intent := _resolve_single_button_intent()

	return _finish_button_buffer(intent)


# ============================================================
# 单键动作解析
# ============================================================

func _resolve_single_button_intent() -> Intent:
	var possession := _get_ball_possession()


	match possession:

		# ----------------------------------------------------
		# 自己持球
		# ----------------------------------------------------

		BallPossession.MYSELF:
			if buffered_b_pressed:
				return Intent.KICK

			if buffered_a_pressed:
				return Intent.PASS


		# ----------------------------------------------------
		# 队友持球
		# ----------------------------------------------------

		BallPossession.TEAMMATE:
			if buffered_b_pressed:
				return Intent.COMMAND_SHOOT

			if buffered_a_pressed:
				return Intent.COMMAND_PASS


		# ----------------------------------------------------
		# 对手持球
		# ----------------------------------------------------

		BallPossession.OPPONENT:
			if buffered_a_pressed:
				return Intent.TACKLE

			if buffered_b_pressed:
				return Intent.ELBOW_STRIKE


		# ----------------------------------------------------
		# 无人持球
		# ----------------------------------------------------

		BallPossession.NONE:
			if (
				buffered_b_pressed
				and _is_moving_horizontally()
			):
				return Intent.ELBOW_DIVE
			if buffered_b_pressed:
				return Intent.KICK

			if buffered_a_pressed:
				return Intent.PASS


	return Intent.IDLE


# ============================================================
# 查询当前球权
# ============================================================

func _get_ball_possession() -> BallPossession:
	var current_carrier := match_context.get_ball_carrier()


	# 无人持球。
	if current_carrier == null:
		return BallPossession.NONE


	# 自己持球。
	if current_carrier == player:
		return BallPossession.MYSELF


	# 队友持球。
	if current_carrier.team_id == player.team_id:
		return BallPossession.TEAMMATE


	# 对手持球。
	return BallPossession.OPPONENT


# ============================================================
# 是否正在纯横向移动
# ============================================================

func _is_moving_horizontally() -> bool:
	return (
		input_component.move_dir.x != 0.0
		and input_component.move_dir.y == 0.0
	)


# ============================================================
# 完成按钮缓冲并返回最终意图
# ============================================================

func _finish_button_buffer(result: Intent) -> Intent:
	is_buffering_buttons = false
	button_buffer_frames = 0

	buffered_a_pressed = false
	buffered_b_pressed = false

	return result
