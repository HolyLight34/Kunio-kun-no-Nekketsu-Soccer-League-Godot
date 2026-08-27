class_name StateMachine
extends Node

@export var initial_state: EntityState # 初始状态
#@export var tick_component: TickComponent
## 🌟 声明一个重置 Tick 请求信号
signal tick_reset_requested
var current_state: EntityState
var states: Dictionary = {}
var actor: CharacterBody2D

# 挂起的延迟切换变量
var _pending_new_state: EntityState = null
var _delay_ticks: int = 0
var is_waiting_delay: bool = false

func _process(delta: float) -> void:
	if current_state:
		current_state.process(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_process(delta)

func init(actor_node: CharacterBody2D) -> void:
	self.actor = actor_node
	
	for child in get_children():
		if child is EntityState:
			child.actor = actor_node
			child.init()
			if child.get("state") != null:
				states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
			
	if initial_state:
		current_state = initial_state
		current_state.enter()


## 核心 3-Tick 步进
## 🌟 由 Player.gd 在每 3-Tick 触发时调用此方法
func physics_tick() -> void:
	# 1. 拦截：如果处于前摇倒计时，扣减 Tick 并阻断当前状态更新
	if is_waiting_delay:
		Log.debug(Log.Cat.STATE, "延迟倒计时中，剩余 Tick: %d 当前物理帧: %d" % [_delay_ticks, Engine.get_physics_frames()])
		_delay_ticks -= 1
		
		# 倒计时归零，正式触发状态切换
		if _delay_ticks <= 0:
			is_waiting_delay = false
			_perform_actual_switch(_pending_new_state)
			_pending_new_state = null
		return # 🌟 关键：前摇期间，直接拦截，不让旧/新 State 跑逻辑！

	# 2. 正常运行：驱动当前状态的 Tick 逻辑（如计算速度）
	if current_state:
		current_state.physics_tick()
func handle_intent(intent: IntentComponent.Intent, delta: float) -> void:
	# 如果处于前摇倒计时锁定中，可以拦截输入不传给 current_state
	if is_waiting_delay:
		return
		
	if current_state:
		current_state.handle_intent(intent, delta)

func change_state(target_state_name: Variant) -> void:
	_on_transition_requested(current_state, target_state_name)

## 收到状态切换请求
func _on_transition_requested(from: EntityState, to: Variant) -> void:
	if from != current_state or is_waiting_delay:
		return
		
	var target_state: EntityState = states.get(to)
	if not target_state:
		return

	# 1. 如果无前摇，立刻执行切换
	tick_reset_requested.emit()
	if target_state.windup_ticks <= 0:
		Log.debug(Log.Cat.STATE, "%s 开始请求延迟切换，目标 %s 延迟 Tick: %s 物理帧: %d" % [actor.name, target_state.name,_delay_ticks, Engine.get_physics_frames()])
		_perform_actual_switch(target_state)
		# 无前摇状态切入后，立刻重置 Tick 供新状态的物理/逻辑使用
		
	else:
		# 2. 如果有前摇，启动倒计时
		_pending_new_state = target_state
		_delay_ticks = target_state.windup_ticks
		is_waiting_delay = true
		
		# 🌟【关键点】：因为是角色独立 TickComponent，收到请求立刻重置！
		# 从“按下按键的这一帧”开始重新计算精准的 Tick 周期，彻底消除相位延迟
		Log.debug(Log.Cat.STATE, "%s 开始请求延迟切换，目标 %s 延迟 Tick: %s 物理帧: %d" % [actor.name, target_state.name,_delay_ticks, Engine.get_physics_frames()])
		#print(actor.name, " 开始请求延迟切换，目标: ", target_state.name, " 延迟 Tick: ", _delay_ticks," 物理帧： ",Engine.get_physics_frames())

## 真正的原子化状态切换动作
func _perform_actual_switch(target_state: EntityState) -> void:
	if current_state:
		current_state.exit()
		Log.info(Log.Cat.STATE, "%s 状态退出: %s 物理帧: %d" % [actor.name, current_state.name, Engine.get_physics_frames()])
		
	current_state = target_state
	current_state.enter()
	Log.info(Log.Cat.STATE, "%s 状态进入: %s 物理帧: %d" % [actor.name, current_state.name, Engine.get_physics_frames()])
