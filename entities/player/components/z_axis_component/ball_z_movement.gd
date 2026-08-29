# ==============================================================================
# BallZMovement.gd
#
# FC 热血足球 2.5D Z轴运动组件
#
# 内部:
#   8.8 fixed point
#   1 raw = 1/256
#
# 外部:
#   float
#
# FC规则:
#
#   Z += VZ
#   VZ -= 0.5
#
#   落地:
#       Z 保留低8位子像素
#
#   反弹:
#       rebound_raw =
#           max(
#               ((abs(impact_raw)-1)>>1)
#               - loss_raw,
#               0
#           )
#
# ==============================================================================


extends ZMovementBase
class_name BallZMovement



# ==============================================================================
# 常量
# ==============================================================================


## FC重力 $0080

enum GroundType
{
	GRASS,
	TYPE_1,
	MUD,
	SAND
}



## ROM $90CA-$90D9
##
## [干球, 湿球]

const FC_BOUNCE_LOSS:Array = [

	[1.0, 2.0],      # 草地

	[2.0, 4.0],      # 特殊地面

	[8.0,16.0],      # 泥地

	[8.0,16.0]       # 沙地
]



# ==============================================================================
# 信号
# ==============================================================================

signal finished



# ==============================================================================
# 视觉
# ==============================================================================


@export_group("Visual")


## 视觉节点，只负责Z高度偏移




# ==============================================================================
# 足球参数
# ==============================================================================


@export_group("FC Ground")


@export var ground_type:GroundType = GroundType.GRASS


## $050D bit7

@export var wet_ball:bool = false
@export var grarty_entry: bool = true
var shadow_visible: bool = false
var _finished_delay_ticks: int = -1
func should_show_shadow() -> bool:
	return shadow_visible
# ==============================================================================
# 物理状态
# ==============================================================================




# ==============================================================================
# 生命周期
# ==============================================================================


# ==============================================================================
# Raw转换
# ==============================================================================




# ==============================================================================
# 外部接口
# ==============================================================================



## 起球

func launch(
	initial_velocity:float
)->void:
	shadow_visible = true
	apply_vertical_velocity(initial_velocity)


# ==============================================================================
# Z逻辑步
# ==============================================================================

# ==============================================================================
# 落地
# ==============================================================================
func _check_landing() -> bool:
	return z_height_raw < 0 and z_velocity_raw < 0
func process_z_step() -> void:
	if _finished_delay_ticks >= 0:
		if _finished_delay_ticks > 0:
			_finished_delay_ticks -= 1
			return

		_finished_delay_ticks = -1
		finished.emit()
		return
	if not is_in_air:
		return
	# 当前 VZ 就是这一整个 Tick 的 Z 位移。
	tick_displacement_raw = z_velocity_raw
	# 新的一段三帧运动开始。
	tick_motion_frame = 0
	# FC：
	# Z += VZ
	# VZ -= 0.5
	#
	# Z += VZ 现在由下面 3 个 Physics Frame 完成。
	if is_in_air and z_velocity_raw > 0 and not shadow_visible:
		shadow_visible = true
	if grarty_entry:
		z_velocity_raw -= _to_raw(GRAVITY)
func _process_landing()->void:
	# FC:
	# 保留低8位子像素
	shadow_visible = false
	_apply_landing_height_correction()
	_calculate_rebound_velocity_raw()
	landed.emit()
	if z_velocity_raw > 0:
		is_in_air = true
		return
	# 无法继续反弹
	z_velocity_raw = 0
	is_in_air = false
	_finished_delay_ticks = 1
# ==============================================================================
# FC落地高度修正
# ==============================================================================
func _apply_landing_height_correction()->void:
	# 保留低8位
	z_height_raw &= 255
# ==============================================================================
# FC反弹计算
# ==============================================================================
func _calculate_rebound_velocity_raw()->void:
	print("下降",z_velocity_raw)
	var impact_velocity_raw:int = abs(
		z_velocity_raw
	)
	var rebound_velocity_raw:int = (
		(impact_velocity_raw - 1)
		>> 1
	)
	rebound_velocity_raw -= (
		_get_bounce_loss_raw()
	)
	z_velocity_raw = maxi(
		rebound_velocity_raw,
		0
	)
	print("反弹",z_velocity_raw)
# ==============================================================================
# 反弹损耗
# ==============================================================================
func _get_bounce_loss_raw()->int:
	var loss:float = FC_BOUNCE_LOSS[
		int(ground_type)
	][
		1 if wet_ball else 0
	]
	return _to_raw(
		loss
	)
