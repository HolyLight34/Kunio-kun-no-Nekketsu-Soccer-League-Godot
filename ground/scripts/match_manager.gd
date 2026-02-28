@tool
extends Node

const TEAM_SIZE: int = 6
@onready var ball: Ball = $Ball

@export var sc: PackedScene
@export var team1: Array[PlayerStats]:
	set(value):
		if value.size() > TEAM_SIZE:
			value = value.slice(0, TEAM_SIZE)
		team1 = value
@export var team2: Array[PlayerStats]:
	set(value):
		if value.size() > TEAM_SIZE:
			value = value.slice(0, TEAM_SIZE)
		team2 = value


func _ready() -> void:
	for t in self.get_children():
		var team_data
		if t.name == "HomeTeam":
			team_data = team1
			spawn_team(t, team_data)
		elif t.name == "HomeTeam":
			team_data = team2
			spawn_team(t, team_data)
	ball.carrier = $HomeTeam/Marker2D.get_child(0)
	pass


func spawn_team(parent_node: Node, stats_list: Array[PlayerStats]):
	# 1. 拿到所有的位置点
	var markers = parent_node.get_children().filter(func(node): return node is Marker2D)

	# 2. 核心逻辑：取两个数组中较短的那个长度
	# 这样即使资源填少了，或者位置点放少了，都不会导致 index out of bounds 报错
	var spawn_count = min(markers.size(), stats_list.size())

	# 3. 使用自动迭代的 range
	for i in range(spawn_count):
		var marker = markers[i] # 拿到第 i 个坑
		var stats = stats_list[i] # 拿到第 i 个萝卜

		var player: Player = sc.instantiate()
		player.stats = stats # 注入数据
		marker.add_child(player)
		if parent_node.name == "HomeTeam":
			player.get_node_or_null("Sprite2D").flip_h = true
			#print(player)
			#player.should_flip = true
			pass

		player.global_position = marker.global_position
