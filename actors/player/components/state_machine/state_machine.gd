
class_name StateMachine
extends Node


@export var initial_state: EntityState


var current_state: EntityState

var _states: Dictionary = {}
var _actor: CharacterBody2D


## 初始化状态机
func initialize(actor_node: CharacterBody2D) -> void:
	_actor = actor_node

	for child in get_children():
		if not child is EntityState:
			continue

		var state_node := child as EntityState

		state_node.actor = actor_node

		# 获取状态编号
		var state_id := state_node.get_state_id()

		# 检查状态编号
		if state_id < 0:
			push_error(
				"StateMachine: 状态 %s 没有设置有效的状态编号"
				% state_node.name
			)
			continue

		# 检查重复编号
		if _states.has(state_id):
			push_error(
				"StateMachine: 重复的状态编号 %d"
				% state_id
			)
			continue

		# 注册状态
		_states[state_id] = state_node

		# 连接状态切换请求
		state_node.transition_requested.connect(
			_on_transition_requested
		)

	# 进入初始状态
	if initial_state:
		var initial_state_id := initial_state.get_state_id()

		if _states.get(initial_state_id) != initial_state:
			push_error(
				"StateMachine: 初始状态没有正确注册"
			)
			return

		current_state = initial_state
		current_state.enter(null)


## 每个对象逻辑步调用一次
func logic_tick(intent) -> void:
	if intent != PlayerIntentResolver.Intent.NONE:
		handle_intent(intent)

	if current_state:
		current_state.logic_tick()


## 处理输入意图
func handle_intent(
	intent: PlayerIntentResolver.Intent,
) -> void:
	if current_state:
		current_state.handle_intent(intent)


## 切换状态
## 立即退出当前状态并进入目标状态。
## data 会传递给目标状态的 enter()。
func change_state(
	target_state_id: int,
	data: Variant = null
) -> void:
	var target_state := get_state(target_state_id)

	if not target_state:
		return

	if target_state == current_state:
		return

	if current_state:
		current_state.exit()

		Log.info(
			Log.Cat.STATE,
			"%s 状态退出: %s"
			% [_actor.name, current_state.name]
		)

	current_state = target_state

	current_state.enter(data)

	Log.info(
		Log.Cat.STATE,
		"%s 状态进入: %s"
		% [_actor.name, current_state.name]
	)

## 判断当前是否处于指定状态
func is_in_state(target_state_id: int) -> bool:
	return current_state != null \
		and current_state.get_state_id() == target_state_id


## 获取当前状态编号
func get_current_state_id() -> int:
	if not current_state:
		return -1

	return current_state.get_state_id()


## 根据编号获取状态节点
func get_state(target_state_id: int) -> EntityState:
	var target_state := _states.get(target_state_id) as EntityState

	if not target_state:
		push_warning(
			"StateMachine: 找不到状态编号 %d"
			% target_state_id
		)

	return target_state


## 接收状态自身发出的切换请求
func _on_transition_requested(
	from: EntityState,
	to: int,
	data: Variant
) -> void:
	if from != current_state:
		return

	change_state(to, data)
