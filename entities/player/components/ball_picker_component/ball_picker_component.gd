class_name BallPickerComponent
extends Area2D

# 当成功捡到球时，向外发射这个信号，把足球的实例传出去
signal ball_picked_up(ball_node: Node2D)

@export var player: Player # 引用宿主球员

# 外部总开关：状态机可以随时通过它来剥夺球员的捡球权限
#var disabled: bool = false:
	#set(value):
		#disabled = value
		## 性能优化：关闭组件时，顺便关闭物理碰撞监测
		#monitoring = !value

func _ready() -> void:
	# 强行连接 Godot 自带的区域进入信号
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	#if disabled:
		#return
		
	# 1. 严格检查对方是不是足球（假设你的足球类名叫 Ball）
	if body is Ball:
		# 2. 核心检查：足球目前必须是“自由身”（没被别人抱着），且高度接近地面
		if body.is_free and body.z_height < 10.0:
			# 3. 核心检查：球员自身的状态必须允许持球（比如不能是受伤、倒地状态）
			if _can_player_pick_up():
				_secure_ball(body)

# 内部判定：结合状态机看目前能不能捡球
func _can_player_pick_up() -> bool:
	if not player or not player.sm:
		return false
		
	var current_state = player.sm.current_state.name
	# 黑名单制：如果是受伤或者已经被罚下，绝对不抓球
	if current_state in ["Hurt", "KnockedOut", "Frozen"]:
		return false
	return true

# 实施执行：把球吸过来并绑定
func _secure_ball(ball: Ball) -> void:
	# 1. 让足球自己进入“被持有”模式（关闭它自己的物理滑行和重力）
	ball.set_carried_by(player)
	
	# 2. 发射信号，通知 Player 发生历史性会晤
	ball_picked_up.emit(ball)
