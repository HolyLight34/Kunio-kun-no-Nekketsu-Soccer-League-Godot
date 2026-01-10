class_name StateIdle
extends State

var last_action: String = "" # 上一次键名
var timestamp: int = 0 # 时间戳


func init() -> void:
	pass


func enter() -> void:
	player.animation_player.play("idle")
	player.velocity = Vector2.ZERO
	pass


func exit() -> void:
	pass


func handle_input(event: InputEvent) -> State:
	if event is InputEventMouse: # 过滤鼠标事件
		return null
	if event.is_action_pressed(player.direction_dic[player.Action.SHOOT]):
		return shoot
	for action in player.key_to_vector.keys(): # 遍历方向键名
		if event.is_action_pressed(action):
			var current_time = Time.get_ticks_msec() # 记录当前按下时间
			var duration = current_time - timestamp # 距离上一次按下的时间差
			if action == last_action and duration < 300: # 双击成功：方向相同且在 300ms 内
				return run
			else:
				# 第一次按下，或者换了方向，或者超时了
				# 更新最后一次按下的动作和时间戳
				last_action = action
				timestamp = current_time
	return nex_state


func process(_delta: float) -> State:
	if player.direction != Vector2.ZERO:
		if player.direction != Vector2.DOWN and player.direction != Vector2.UP:
			player.facing_direction = player.direction
		return walk
	return nex_state


func physics_process(_delta: float) -> State:
	return nex_state
