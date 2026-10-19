
@tool
class_name FCShapeLibrary
extends Resource


@export var shapes: Array[FCShape] = []


## 根据 FC Shape 编号查询资源。
func get_shape(shape_id: int) -> FCShape:
	for shape in shapes:
		if shape == null:
			continue

		if shape.shape_id == shape_id:
			return shape

	return null


## 检查编号是否存在。
func has_shape(shape_id: int) -> bool:
	return get_shape(shape_id) != null
