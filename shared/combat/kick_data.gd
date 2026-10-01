class_name KickData
extends RefCounted

enum KickType {
	NORMAL,
	HEADER,
	BICYCLE_KICK,
}

var kick_type: KickType
var direction: Vector2
var endurance: int
var skill_data: Variant = null
