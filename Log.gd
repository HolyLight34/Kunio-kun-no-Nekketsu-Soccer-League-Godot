class_name GameLogger
extends Node

enum Level { DEBUG, INFO, WARN, ERROR }

# 🌟 1. 用标准的 Enum 定义分类（IDE 代码联想极佳，且强类型安全）
enum Cat { 
	PHYSICS, 
	STATE, 
	INPUT, 
	BALL, 
	TICK 
}

# 🌟 2. 用 Enum 作为 Dictionary 的 Key
var enabled_categories: Dictionary = {
	Cat.PHYSICS: true,   # 物理/位移/Tick 计算
	Cat.STATE: true,      # 状态机切换
	Cat.INPUT: false,     # 意图/按键解析
	Cat.BALL: true,       # 球权/抢球/碰撞
	Cat.TICK: false       # 3-Tick 驱动事件
}

var min_level: Level = Level.DEBUG

## 核心日志输出函数（注意参数类型限制为了 Cat 枚举）
func log_msg(category: Cat, message: String, level: Level = Level.INFO) -> void:
	if level < min_level:
		return
		
	if enabled_categories.has(category) and not enabled_categories[category]:
		return

	var frame := Engine.get_physics_frames()
	var time_str := Time.get_time_string_from_system()
	
	# 🌟【关键点】：用 Cat.keys()[category] 把枚举数字转换为对应的文本名称（如 "STATE"）
	var cat_name :String= Cat.keys()[category]
	
	var log_str := "[%s][F:%d][%s][%s] %s" % [
		time_str, 
		frame, 
		cat_name, 
		Level.keys()[level], 
		message
	]

	match level:
		Level.DEBUG:
			print_rich("[color=gray]" + log_str + "[/color]")
		Level.INFO:
			print_rich("[color=white]" + log_str + "[/color]")
		Level.WARN:
			print_rich("[color=yellow]" + log_str + "[/color]")
			push_warning(log_str)
		Level.ERROR:
			print_rich("[color=red]" + log_str + "[/color]")
			push_error(log_str)

## 快捷调用方法
func debug(category: Cat, msg: String) -> void: log_msg(category, msg, Level.DEBUG)
func info(category: Cat, msg: String) -> void: log_msg(category, msg, Level.INFO)
func warn(category: Cat, msg: String) -> void: log_msg(category, msg, Level.WARN)
func error(category: Cat, msg: String) -> void: log_msg(category, msg, Level.ERROR)
