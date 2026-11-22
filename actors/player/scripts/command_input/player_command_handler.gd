class_name PlayerCommandHandler
extends RefCounted


const ACCEPTABLE_STATES: Array[Types.PlayerStateType] = [
	Types.PlayerStateType.IDLE,
	Types.PlayerStateType.WALK,
	Types.PlayerStateType.RUN,
	Types.PlayerStateType.JUMP,
]


static func resolve_next_state(
	commands: Array[Types.PlayerCommandType],
	current_state: Types.PlayerStateType,
	input_direction: Vector2,
	current_ball_possession: Types.BallPossession,
	facing_direction: Vector2,
	is_nearest_to_ball: bool
) -> Types.PlayerStateType:
	if not _can_accept_command(current_state):
		return current_state

	# 1. 优先解释按键指令（按当前球权分类）
	if not commands.is_empty():
		if not is_nearest_to_ball and (commands.has(Types.PlayerCommandType.A) or commands.has(Types.PlayerCommandType.B)):
			return Types.PlayerStateType.ORDER
		var action_state := current_state
		match current_ball_possession:
			Types.BallPossession.NONE:
				action_state = _resolve_no_ball_command(commands, input_direction, current_state, facing_direction)
			Types.BallPossession.MYSELF:
				action_state = _resolve_myself_command(commands, input_direction, current_state, facing_direction)
			Types.BallPossession.TEAMMATE:
				action_state = _resolve_teammate_command(commands, input_direction, current_state, facing_direction)
			Types.BallPossession.OPPONENT:
				action_state = _resolve_opponent_command(commands, input_direction, current_state, facing_direction)

		if action_state != current_state:
			return action_state

		# 通用双击奔跑（所有球权下规则相同，统一写在这里）
		if commands.has(Types.PlayerCommandType.DOUBLE_TAP) and _can_start_run(current_state):
			return Types.PlayerStateType.RUN

	# 2. 没有触发特殊指令时，再处理普通方向移动切换
	if current_state == Types.PlayerStateType.IDLE and input_direction != Vector2.ZERO:
		return Types.PlayerStateType.WALK

	if current_state == Types.PlayerStateType.WALK and input_direction == Vector2.ZERO:
		return Types.PlayerStateType.IDLE

	if current_state == Types.PlayerStateType.RUN and _is_opposite_facing(input_direction, facing_direction):
		return Types.PlayerStateType.BRAKE

	return current_state


static func _can_accept_command(current_state: Types.PlayerStateType) -> bool:
	return current_state in ACCEPTABLE_STATES


static func _can_start_run(current_state: Types.PlayerStateType) -> bool:
	return current_state in [Types.PlayerStateType.IDLE, Types.PlayerStateType.WALK]


static func _is_opposite_facing(input_direction: Vector2, facing_direction: Vector2) -> bool:
	return (input_direction.x * facing_direction.x) < 0.0


static func _resolve_no_ball_command(
	commands: Array[Types.PlayerCommandType],
	input_direction: Vector2,
	current_state: Types.PlayerStateType,
	facing_direction: Vector2,
) -> Types.PlayerStateType:
	if commands.has(Types.PlayerCommandType.A_B):
		if current_state == Types.PlayerStateType.JUMP:
			return Types.PlayerStateType.PASS
		return Types.PlayerStateType.JUMP

	if commands.has(Types.PlayerCommandType.A):
		return Types.PlayerStateType.PASS

	if commands.has(Types.PlayerCommandType.B):
		if current_state == Types.PlayerStateType.WALK:
			return Types.PlayerStateType.DIVING_HEADER
		if current_state == Types.PlayerStateType.JUMP and _is_opposite_facing(input_direction, facing_direction):
			return Types.PlayerStateType.BICYCLE_KICK
		return Types.PlayerStateType.KICK

	return current_state


static func _resolve_myself_command(
	commands: Array[Types.PlayerCommandType],
	input_direction: Vector2,
	current_state: Types.PlayerStateType,
	facing_direction: Vector2,
) -> Types.PlayerStateType:
	if commands.has(Types.PlayerCommandType.A_B):
		match current_state:
			Types.PlayerStateType.IDLE:
				return Types.PlayerStateType.STATIONARY_FLICK
			Types.PlayerStateType.WALK:
				return Types.PlayerStateType.MOVING_FLICK
			Types.PlayerStateType.RUN:
				return Types.PlayerStateType.JUMP
			Types.PlayerStateType.JUMP:
				return Types.PlayerStateType.PASS

	if commands.has(Types.PlayerCommandType.A):
		return Types.PlayerStateType.PASS

	if commands.has(Types.PlayerCommandType.B):
		if current_state == Types.PlayerStateType.JUMP and _is_opposite_facing(input_direction, facing_direction):
			return Types.PlayerStateType.BICYCLE_KICK
		return Types.PlayerStateType.KICK

	return current_state


static func _resolve_teammate_command(
	_commands: Array[Types.PlayerCommandType],
	_input_direction: Vector2,
	current_state: Types.PlayerStateType,
	_facing_direction: Vector2,
) -> Types.PlayerStateType:
	# 按实际动作填入
	return current_state


static func _resolve_opponent_command(
	commands: Array[Types.PlayerCommandType],
	_input_direction: Vector2,
	current_state: Types.PlayerStateType,
	_facing_direction: Vector2,
) -> Types.PlayerStateType:
	if commands.has(Types.PlayerCommandType.A_B):
		if current_state == Types.PlayerStateType.JUMP:
			return Types.PlayerStateType.PASS
		return Types.PlayerStateType.JUMP

	if commands.has(Types.PlayerCommandType.A):
		if current_state == Types.PlayerStateType.JUMP:
			return Types.PlayerStateType.AIR_KICK
		return Types.PlayerStateType.TACKLE

	if commands.has(Types.PlayerCommandType.B):
		return Types.PlayerStateType.ELBOW_STRIKE

	return current_state
