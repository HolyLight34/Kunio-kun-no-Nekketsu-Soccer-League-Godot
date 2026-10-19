
@tool
class_name FCCollisionShapeCatalog
extends Resource


@export var profiles: Array[FCCollisionRegionProfile] = []


func get_profile(
	shape_id: int
) -> FCCollisionRegionProfile:
	for profile in profiles:
		if profile == null:
			continue

		if profile.shape_id == shape_id:
			return profile

	return null
