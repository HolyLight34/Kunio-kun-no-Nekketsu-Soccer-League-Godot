class_name Field
extends Node


## Field
##
## 足球场的场地信息入口。
##
## Field 保存当前球场的基础地面类型，并管理球场中的特殊地形区域。
## 特殊地形区域由当前 Field 的直接子节点 SpecialGroundRegion 定义。
##
## 外部可以通过世界逻辑坐标查询当前位置的特殊地形。
##
## 本类负责：
## - 保存当前球场的基础地面类型。
## - 收集当前球场中的特殊地形区域。
## - 根据世界逻辑坐标查询特殊地形。
##
## 本类不负责：
## - 足球湿度变化。
## - 角色移动规则。
## - 足球反弹规则。
## - 决定 Player / Ball 如何响应地形。


## 球场的基础地面类型。
##
## NORMAL：
## 草地和土地。目前两者使用相同的基础物理规则。
##
## SAND：
## 沙地。使用沙地对应的基础物理规则。
enum GroundType {
	NORMAL,
	SAND,
}


## 球场中的特殊地形效果。
##
## NONE：
## 当前坐标没有特殊地形。
##
## PUDDLE：
## 积水区域。
##
## MUD：
## 泥地区域。
enum GroundEffect {
	NONE,
	PUDDLE,
	MUD,
}


## 当前球场的基础地面类型。
@export var ground_type: GroundType = GroundType.NORMAL


## 当前球场中的所有特殊地形区域。
##
## 在 _ready() 时自动收集当前 Field 的直接子节点，
## 外部不需要手动配置。
var _special_ground_regions: Array[SpecialGroundRegion] = []


func _ready() -> void:
	_collect_special_ground_regions()


## 返回当前球场的基础地面类型。
func get_ground_type() -> GroundType:
	return ground_type


## 返回指定世界逻辑坐标所在的特殊地形。
##
## 按 SpecialGroundRegion 在场景树中的顺序进行检查。
## 返回第一个包含该坐标的特殊地形。
##
## 如果当前位置不属于任何特殊区域，则返回 NONE。
func get_ground_effect_at(world_position: Vector2) -> GroundEffect:
	for region in _special_ground_regions:
		if region.contains_point(world_position):
			return region.effect

	return GroundEffect.NONE


## 收集当前 Field 直接持有的所有特殊地形区域。
func _collect_special_ground_regions() -> void:
	_special_ground_regions.clear()

	for child in get_children():
		if child is SpecialGroundRegion:
			_special_ground_regions.append(child)
