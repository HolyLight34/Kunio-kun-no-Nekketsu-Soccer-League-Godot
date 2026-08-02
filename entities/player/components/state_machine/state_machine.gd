class_name StateMachine
extends Node

@export var initial_state: EntityState # 初始状态

var current_state: EntityState # 当前状态
var states: Dictionary = {}
var actor: CharacterBody2D    # 🎯 【新增】：通用演员引用，人、球、AI 统统都是它

func _process(delta: float) -> void:
	if current_state:
		current_state.process(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)
		# 只有通过了防呆检查，才去执行转身
## 【升级】：初始化时，把自己也和 actor 绑定
func init(actor_node: CharacterBody2D) -> void:
	self.actor = actor_node # 🎯 【核心修复】：状态机自己得记住当前控制的是谁
	
	for child in get_children():
		if child is EntityState:
			child.actor = actor_node
			child.init()
			if child.get("state") != null:
				states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
	if initial_state:
		initial_state.enter()
		current_state = initial_state


func handle_intent(intent: IntentComponent.Intent, delta: float) -> void:
	if current_state:
		# 状态机把球传给当前状态，实现你想要的“拦截”
		current_state.handle_intent(intent, delta)
# ==========================================
# 🚪 状态机对外开放的“正门”（公开的 API 接口）
# ==========================================

## 供外部脚本（如 Player、AI 决策、裁判系统）主动请求切换状态
func change_state(target_state_name: Variant) -> void:
	# 完美的正向代理：
	# 外部人敲正门，状态机在内部代替当前状态，安全地顺着大底座流程走
	print(states)
	_on_transition_requested(current_state, target_state_name)
func _on_transition_requested(from: EntityState, to: Variant) -> void:
	if from != current_state:
		return
		
	var new_state: EntityState = states[to]
	if not new_state:
		return
	if current_state:
		current_state.exit()
		print(actor.name, " 状态退出: ", current_state.name) # 加上名字，Debug 更清晰
	new_state.enter()
	print(actor.name, " 状态进入: ", new_state.name)
	current_state = new_state
