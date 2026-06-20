@tool
extends Node
class_name Team
const TEAM_SIZE: int = 6
#@onready var ball: Ball = $Ball

#@export var sc: PackedScene
@export var team: Array[PlayerStats]:
	set(value):
		if value.size() > TEAM_SIZE:
			value = value.slice(0, TEAM_SIZE)
		team = value
