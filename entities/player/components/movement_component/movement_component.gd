extends Node
class_name MovementComponent

@export var body: CharacterBody2D # 引用宿主（人或球）

# 基础物理参数（在 Inspector 面板里，人给低点，球给高点）
@export var friction: float = 200.0       # 正常滚行/滑行摩擦力（FC热血核心）
@export var brake_friction: float = 1200.0 # 球员急停刹车时的摩擦力

func _ready():
	if not body:
		body = get_parent() as CharacterBody2D

## 🏃 接口 A：主动动力驱动（球员专属）
## 特点：还原 FC 热血足球“瞬间起步”的硬核手感
func apply_input_movement(input_dir: Vector2, target_speed: float):
	if input_dir != Vector2.ZERO:
		# 瞬间达到最高速，没有任何肉泥感起步
		body.velocity = input_dir * target_speed
	
	# 注意：这里我们移除了 else 里的 Vector2.ZERO，把减速权交给物理状态！
	body.move_and_slide()


## ⚽ 接口 B：纯物理惯性衰减（人球通用！）
## 特点：处理足球被踢出后的滑行、或者球员松开按键后的“魔性溜冰滑行”
func apply_pure_friction(delta: float, custom_friction: float = -1.0):
	# 如果没有传入特定的摩擦力，就使用默认的正常摩擦力
	var current_friction = friction if custom_friction < 0.0 else custom_friction
	
	if body.velocity.length() > 0:
		# 使用 move_toward 顺滑地向 0 衰减速度
		body.velocity = body.velocity.move_toward(Vector2.ZERO, current_friction * delta)
	
	body.move_and_slide()
