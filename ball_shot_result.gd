
class_name BallShotResult
extends RefCounted


## 根据足球 Z 高度选择的射门计算分支。
enum ShotHeightCategory {
	BELOW_GROUND,
	GROUND,
	LOW_AIR,
	HIGH_AIR,
}


var is_valid: bool = true

## 射门分类。
var height_category: ShotHeightCategory = ShotHeightCategory.GROUND
var shot_mode: Types.ShotMode = Types.ShotMode.NORMAL

## 水平运动。
var direction: Vector2 = Vector2.ZERO
var horizontal_velocity: Vector2 = Vector2.ZERO
var initial_position: Vector2 = Vector2.ZERO

## Z 轴运动。
var initial_z_height: float = 0.0
var z_velocity: int = 0

## 扣除预推进 3 步后的持续时间。
var duration_ticks: int = 0

## 攻击参数。
var power: int = 0
