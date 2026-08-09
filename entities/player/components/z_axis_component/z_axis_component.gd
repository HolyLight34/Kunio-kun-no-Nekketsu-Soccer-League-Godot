# ==============================================================================
# 文件路径: res://scripts/components/z_axis_component.gd
# 描述: 2.5D 高度与垂直物理逻辑组件 (人球通用)
# ==============================================================================
extends Node
class_name ZAxisComponent

# ==============================================================================
# 1. 信号定义 (Signals) - 符合 GDScript 过去式命名规范
# ==============================================================================
## 离地/起飞/起跳信号 (适用于：角色起跳、足球被踢飞、足球落地再次反弹)
signal launched(initial_z_velocity: float)

## 高度与垂直速度实时更新信号 (用于：实时缩放影子、球网/守门员拦截高度判定)
signal height_changed(height: float, velocity: float)

## 抛物线最高点/极点信号 (用于：上升与下落动画切换、滞空特效)
signal apex_reached

## 精准触地/落地信号 (用于：角色落地播放音效/硬直，足球触地计算反弹)
signal landed(impact_velocity: float)


# ==============================================================================
# 2. 导出属性配置 (Exported Properties)
# ==============================================================================
## 绑定的视觉挂载节点 (通常为 VisualPivot，其 position.y 会随高度做负向偏移)
@export var visual_pivot: Node2D
## 垂直重力扣减步长 (FC 标准基准为 0.5)
@export var gravity_step: float = 0.5
## 在 Inspector 里直接把 ShadowSprite 拖进来
@export var shadow_sprite: Sprite2D

# ==============================================================================
# 3. 动态运行状态变量 (Runtime State Variables)
# ==============================================================================
## 当前距离地面的 Z 轴物理高度
var z_height: float = 0.0

## 当前 Z 轴垂直速度 (正数代表上升，负数代表下落)
var z_velocity: float = 0.0

## 是否处于空中/滞空状态
var is_in_air: bool = false

## 上一 Tick 的 Z 轴速度 (内部变量，用于判定抛物线顶点)
var _previous_z_velocity: float = 0.0


# ==============================================================================
# 4. 生命周期 (Lifecycle)
# ==============================================================================
func _ready() -> void:
	if visual_pivot == null:
		push_warning("ZAxisComponent 警告: 未在 Inspector 中关联 visual_pivot 节点！")


# ==============================================================================
# 5. 核心 API (Public Methods)
# ==============================================================================
## 施加垂直冲量 (角色跳跃 / 足球被踢飞 / 足球反弹)
func apply_impulse(initial_z_vel: float) -> void:
	z_velocity = initial_z_vel
	is_in_air = true
	_previous_z_velocity = z_velocity
	
	launched.emit(initial_z_vel)
	height_changed.emit(z_height, z_velocity)


## 垂直物理更新入口 (由外部 3-Tick 信号每 3 帧定时驱动调用一次)
func process_z_step() -> void:
	
	if not is_in_air and z_height <= 0.0:
		return
	_previous_z_velocity = z_velocity
	z_height += z_velocity

	# 1. 落地判定
	if z_height <= 0.0:
		z_height = 0.0
		is_in_air = false
		var impact := z_velocity
		z_velocity = 0.0 # 强制修正归零，若为足球反弹可由外部在 landed 信号响应中再次 apply_impulse
		shadow_sprite.visible = false
		_update_visual_position()
		height_changed.emit(z_height, z_velocity)
		landed.emit(impact) # 发射触地信号并携带冲击速度
		return

	# 2. 空中扣减重力
	z_velocity -= gravity_step

	# 3. 顶点判定 (速度由正转负的瞬间)
	if _previous_z_velocity > 0.0 and z_velocity <= 0.0:
		apex_reached.emit()
	print("物理帧：",Engine.get_physics_frames(),"当前高度：",z_height)

	# 4. 更新视觉渲染并抛出高度更新信号
	# 只要在空中，影子就始终显示（解耦了 AnimationPlayer）
	shadow_sprite.visible = true
	_update_visual_position()
	height_changed.emit(z_height, z_velocity)


## 强制重置高度状态 (用于得分复位、出界重新发球等场景)
func reset_height() -> void:
	z_height = 0.0
	z_velocity = 0.0
	is_in_air = false
	_previous_z_velocity = 0.0
	_update_visual_position()
	height_changed.emit(z_height, z_velocity)


# ==============================================================================
# 6. 私有辅助函数 (Private Helpers)
# ==============================================================================
## 更新视觉节点的 Y 轴偏移 (2D 中 Y 轴负方向代表向上)
func _update_visual_position() -> void:
	if visual_pivot:
		visual_pivot.position.y = -z_height
		#print(z_height)
