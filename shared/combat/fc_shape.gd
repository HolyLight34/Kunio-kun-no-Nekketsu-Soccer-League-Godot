
@tool
class_name FCShape
extends Resource


## FC 原版 Shape 编号。
@export_range(0, 255, 1)
var shape_id: int = 0:
	set(value):
		if shape_id == value:
			return
		shape_id = value
		emit_changed()


## FC 原始五字节数据。
@export var raw_data: PackedByteArray = PackedByteArray([
	0x08, 0x04, 0x04, 0x20, 0xE8
]):
	set(value):
		if raw_data == value:
			return

		raw_data = value
		emit_changed()


## 数据是否完整。
func is_valid() -> bool:
	return raw_data.size() == 5
