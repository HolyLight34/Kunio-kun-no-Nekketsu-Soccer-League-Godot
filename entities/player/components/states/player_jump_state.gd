extends PlayerState

@onready var z_axis: ZAxisComponent = owner.get_node("ZAxisComponent")
@onready var anim: AnimationPlayer = owner.get_node("AnimationPlayer")

func enter():
	# 1. 建立信号连接
	#z_axis.lift_started.connect(_on_lift_started)
	#z_axis.peak_hold_started.connect(_on_peak_hold_started)
	#z_axis.falling_started.connect(_on_falling_started)
	#z_axis.grounded.connect(_on_grounded)
	#
	## 2. 启动组件（进入状态的起手式）
	#z_axis.activate_motion(18)
	
	anim.play("jump_up")
	anim.queue("jump_peak")
	anim.queue("jump_down")
	anim.queue("jump_land")
	#await get_tree().physics_frame
	#z_axis.start_jump(18)
# 确保没有重复连接
	if not anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String):
	# 这里才是判断“到底是哪个动画结束了”的最佳位置
	if anim_name == "jump_land":
		print("jump_land 播放完毕，切换状态")
		change_state(State.IDLE)
		# 可选：断开信号以防状态切换回这里时重复触发
		anim.animation_finished.disconnect(_on_animation_finished)
func exit():
	# 3. 必须断开连接！防止内存泄漏和逻辑污染
	#if z_axis.lift_started.is_connected(_on_lift_started):
		#z_axis.lift_started.disconnect(_on_lift_started)
	#if z_axis.peak_hold_started.is_connected(_on_peak_hold_started):
		#z_axis.peak_hold_started.disconnect(_on_peak_hold_started)
	#if z_axis.falling_started.is_connected(_on_falling_started):
		#z_axis.falling_started.disconnect(_on_falling_started)
	#if z_axis.grounded.is_connected(_on_grounded):
		#z_axis.grounded.disconnect(_on_grounded)
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass


func handle_intent(_intent: int, _delta: float) -> void:
	pass
	
func _on_lift_started(_apex):
	anim.play("jump_up")
	print("动画：开始起跳")

func _on_peak_hold_started(_apex):
	anim.play("jump_peak") # 滞空定格
	print("动画：进入滞空定格")

func _on_falling_started():
	anim.play("jump_down")
	print("动画：开始下落")

func _on_grounded():
	anim.play("jump_land")
	print("动画：落地，切换至静止状态")
	await anim.animation_finished
	# 落地后跳转回空闲状态
	change_state(State.IDLE)
