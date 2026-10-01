class_name PassData
extends RefCounted


enum TargetType {
	POSITION,
	OFFSET,
}


## 当前传球目标的描述方式。
var target_type: TargetType


## POSITION 模式使用。
## 表示传球的绝对逻辑目标位置。
var target_position: Vector2


## OFFSET 模式使用。
## 表示相对于足球命中时位置的目标偏移。
var target_offset: Vector2i


## 创建“绝对目标位置”传球数据。
static func from_position(position: Vector2) -> PassData:
	var data := PassData.new()

	data.target_type = TargetType.POSITION
	data.target_position = position

	return data


## 创建“相对足球位置偏移”传球数据。
static func from_offset(offset: Vector2i) -> PassData:
	var data := PassData.new()

	data.target_type = TargetType.OFFSET
	data.target_offset = offset

	return data
