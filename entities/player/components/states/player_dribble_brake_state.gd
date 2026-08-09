extends PlayerState


func enter():
	player.step_animation_component.play(anim_name)
	pass


func exit() -> void:
	pass


func process(_delta: float) -> void:

	pass


func physics_process(_delta: float) -> void:
	
	pass
