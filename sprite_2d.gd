extends Sprite2D

# 1. 算法内部使用的物理变量
var height: float = 68.0    # 当前高度
var velocity: int = 1       # 初始速度差
var step: int = 0           # 运行步数

# 2. 控制和状态变量
var is_falling: bool = false
var start_y: float = 0.0          # 记录地面的 Y 坐标
var frame_counter: int = 0        # 帧计数器，用来实现 3 帧间隔

# 每 3 帧运行一次的设置
const FRAMES_PER_STEP: int = 3

func _ready() -> void:
	# 记录物体当前的位置为“地面” (高度 0 时的位置)
	start_y = global_position.y
	# 自动触发一次下落测试
	start_fall()

func _physics_process(_delta: float) -> void:
	# 随时按空格键重新测试
	if Input.is_action_just_pressed("ui_accept") and not is_falling:
		start_fall()

	if is_falling:
		# 只有当帧计数器达到 3 帧时，才去调用算法获取下一个高度
		if frame_counter == 0:
			var current_height = _get_next_height_algorithmic()
			
			# 将算法计算的高度转换为 Godot 屏幕 Y 坐标 (向上减，向下加)
			global_position.y = start_y - current_height
			
			# 打印测试：你可以直接在控制台看到输出与你的测试数据完全一致
			print("步数: ", step - 1, " | 当前高度: ", current_height)
			
			# 如果高度落到 0 了，停止下落
			if current_height <= 0.0:
				is_falling = false
				global_position.y = start_y
				print("--- 落地了！---")
				return
		
		# 每一帧自增，模 3 循环，确保 0 -> 1 -> 2 -> 0 规律循环
		frame_counter = (frame_counter + 1) % FRAMES_PER_STEP


# 你的核心算法函数
# 纯粹利用 0,0,1,1 周期规律实现的完美算法
func _get_next_height_algorithmic() -> float:
	if step == 0:
		step += 1
		return height # 第 0 步保持 68
		
	# 🎯 完美应用你发现的规律：每 4 步一组
	var group = (step - 1) / 4      # 第几组 (0, 1, 2...)
	var index = (step - 1) % 4      # 组内索引 (0, 1, 2, 3)
	
	var odd_number = group * 2 + 1  # 这一组的核心奇数 (1, 3, 5...)
	
	var velocity = odd_number
	if index == 3:
		velocity = odd_number + 1   # 组内第 4 个数是紧接着的偶数
		
	# 执行下落
	height -= velocity
	height = max(height, 0.0)
	
	step += 1
	return height
#func _get_next_height_algorithmic() -> float:
	#if step == 0:
		#step += 1
		#return height # 步数 0 -> 68.0
	#
	## 根据你的天才规律进行计算：
	## 每一个周期（4步）对应一个组索引 (0, 1, 2, 3...)
	#var group_index = (step - 1) / 4
	#
	## 计算该组对应的基础奇数 (第0组是1, 第1组是3, 第2组是5...)
	#var base_odd = 1 + (group_index * 2)
	#
	## 判断是不是每一组的最后一步（第4步）
	#var is_last_in_group = ((step - 1) % 4 == 3)
	#
	## 如果是最后一步，速度就是下一个偶数（基础奇数 + 1）；否则就是奇数本身
	#var current_velocity = base_odd + 1 if is_last_in_group else base_odd
	#
	## 更新高度
	#height -= current_velocity
	#height = max(height, 0.0) # 越界修正
	#
	#step += 1
	#return height

# 初始化/重置状态的方法
func start_fall() -> void:
	is_falling = true
	frame_counter = 0
	
	# 必须重置算法变量，否则下一次下落数据会乱掉
	height = 68.0
	velocity = 1
	step = 0
	
	# 初始定位到 68 像素的高度
	global_position.y = start_y - height
	print("--- 开始下落 ---")
