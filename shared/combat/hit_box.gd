class_name HitBox
extends Area2D

@onready var hit_shape: CollisionShape2D = $CollisionShape2D
@export var source: CharacterBody2D
var hit_info: HitInfo = null
