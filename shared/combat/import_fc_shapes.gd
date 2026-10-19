
@tool
extends EditorScript


const SHAPE_SCRIPT = preload(
	"res://shared/combat/fc_shape.gd"
)

const LIBRARY_SCRIPT = preload(
	"res://shared/combat/fc_shape_library.gd"
	
)

const OUTPUT_PATH := (
	"res://fc_shape_library.tres"
)


## 格式：Shape编号 P0 P1 P2 P3 P4
## 数据来自你提供的 FC Shape 表。
const RAW_ROWS := """
00 08 08 06 10 00
01 08 08 04 20 00
02 08 08 04 18 00
03 10 10 04 10 00
04 F8 10 04 0C 00
05 0C 02 04 0C FC
06 08 02 04 0C FC
07 08 10 04 0C FC
08 0C 04 04 20 E8
09 04 0C 04 20 E8
0A 08 08 04 18 F0
0B 00 10 04 18 F0
0C 08 08 04 20 F0
0D 10 08 04 18 F0
0E 10 00 04 18 F0
0F 04 12 06 14 F4
10 00 10 04 0F 00
11 08 08 04 0C 00
12 08 08 04 20 E8
13 08 08 04 20 FE
14 00 10 04 0C 00
15 08 08 04 20 00
16 08 08 04 0C 00
17 08 10 04 0C 00
18 08 10 04 0C F8
19 10 08 04 0C F8
1A 0C 0C 04 1E FE
1B 0C 0C 04 1E FE
1C 0C 0C 04 1E FE
1D 0C 0C 04 1E FE
1E 04 0C 08 20 00
1F 08 08 04 40 00
20 04 0C 0C 18 00
21 0C 0C 12 20 00
22 20 20 10 20 00
23 08 08 04 20 00
"""


func _run() -> void:
	var rows := _parse_rows()

	# 先完成全部数据校验，避免产生不完整的资源。
	if rows.is_empty():
		push_error("FC Shape 导入取消：没有有效数据。")
		return

	var library = LIBRARY_SCRIPT.new()

	for row in rows:
		var shape = SHAPE_SCRIPT.new()
		shape.shape_id = row["shape_id"]
		shape.raw_data = row["raw_data"]
		library.shapes.append(shape)

	# 创建输出目录。
	var output_directory := OUTPUT_PATH.get_base_dir()
	var absolute_directory := ProjectSettings.globalize_path(
		output_directory
	)

	var directory_error := (
		DirAccess.make_dir_recursive_absolute(
			absolute_directory
		)
	)

	if directory_error != OK:
		push_error(
			"无法创建输出目录：%s，错误码：%d"
			% [output_directory, directory_error]
		)
		return

	# 保存共享 Shape 库。
	var save_error := ResourceSaver.save(
		library,
		OUTPUT_PATH
	)

	if save_error != OK:
		push_error(
			"Shape Library 保存失败，错误码：%d"
			% save_error
		)
		return

	print(
		"FC Shape 导入成功：%d 个 Shape，保存路径：%s"
		% [rows.size(), OUTPUT_PATH]
	)


## 解析并验证全部原始数据。
func _parse_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var imported_ids: Dictionary = {}

	var lines := RAW_ROWS.strip_edges().split("\n")

	for line_number in range(lines.size()):
		var line: String = lines[line_number].strip_edges()

		if line.is_empty():
			continue

		var fields := line.split(" ", false)

		if fields.size() != 6:
			push_error(
				"第 %d 行格式错误，应包含编号和五个字节：%s"
				% [line_number + 1, line]
			)
			return []

		# 先检查每个字段确实是十六进制字节。
		for field in fields:
			if not _is_hex_byte(field):
				push_error(
					"第 %d 行包含无效十六进制数据：%s"
					% [line_number + 1, field]
				)
				return []

		# 使用 String.hex_to_int() 正确解析十六进制。
		var shape_id: int = fields[0].hex_to_int()

		if imported_ids.has(shape_id):
			push_error(
				"重复的 Shape 编号：$%02X（第 %d 行）"
				% [shape_id, line_number + 1]
			)
			return []

		var raw_data := PackedByteArray()

		for i in range(1, 6):
			raw_data.append(fields[i].hex_to_int())

		rows.append({
			"shape_id": shape_id,
			"raw_data": raw_data
		})

		imported_ids[shape_id] = true

	if rows.is_empty():
		push_error("没有解析到任何 Shape 数据。")
		return []

	return rows


## 检查字符串是否为 1～2 位十六进制字节。
func _is_hex_byte(value: String) -> bool:
	if value.is_empty() or value.length() > 2:
		return false

	for i in range(value.length()):
		var character := value.substr(i, 1).to_upper()

		if "0123456789ABCDEF".find(character) == -1:
			return false

	return true
