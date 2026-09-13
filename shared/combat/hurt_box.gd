class_name HurtBox
extends Area2D

@export var target: CharacterBody2D
@onready var hurt_shape: CollisionShape2D = $HurtShape

signal hurt_received(hurt_data: HurtData)


func receive_hurt(hurt_data: HurtData) -> void:
	hurt_received.emit(hurt_data)
