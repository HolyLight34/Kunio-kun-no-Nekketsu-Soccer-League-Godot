@tool # 🎯 1. 声明它是工具脚本，允许在编辑器运行
class_name VisualComponent
extends Node2D

signal animation_finished_custom(anim_name: String)

# --- 【暴露给面板的配置槽位】 ---
@export_group("Head Settings")
@export var head_texture: Texture2D:
	set(value):
		head_texture = value
		if Engine.is_editor_hint() and head_sprite: head_sprite.texture = value

@export var head_hframes: int = 1:
	set(value):
		head_hframes = value
		if Engine.is_editor_hint() and head_sprite: head_sprite.hframes = value

@export var head_vframes: int = 1:
	set(value):
		head_vframes = value
		if Engine.is_editor_hint() and head_sprite: head_sprite.vframes = value


@export_group("Body Settings")
@export var body_texture: Texture2D:
	set(value):
		body_texture = value
		if Engine.is_editor_hint() and body_sprite: body_sprite.texture = value

@export var body_hframes: int = 1:
	set(value):
		body_hframes = value
		# 🎯 核心魔法：当你在面板修改 Hframes 时，底下的 Sprite2D 立刻同步切片！
		if Engine.is_editor_hint() and body_sprite: body_sprite.hframes = value

@export var body_vframes: int = 1:
	set(value):
		body_vframes = value
		# 🎯 核心魔法：当你在面板修改 Vframes 时，底下的 Sprite2D 立刻同步切片！
		if Engine.is_editor_hint() and body_sprite: body_sprite.vframes = value


@export_group("Animation Settings")
@export var anim_library: AnimationLibrary
# --- 【内部节点抓取】 ---
@onready var head_sprite: Sprite2D = $AnimAnchor/HeightAnchor/Head
@onready var body_sprite: Sprite2D = $AnimAnchor/HeightAnchor/Body
@onready var height_anchor: Node2D = $AnimAnchor/HeightAnchor
@onready var shadow: Sprite2D = $Shadow
@onready var anim_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# 🎯 2. 无论是在编辑器还是正式游戏，运行的一瞬间都必须初始化！(去掉那个 is_editor_hint 限制)
	init_visual(
		head_texture, head_hframes, head_vframes,
		body_texture, body_hframes, body_vframes,
		anim_library
	)
	
	# 游戏运行时的信号连接
	if not Engine.is_editor_hint():
		if anim_player:
			anim_player.animation_finished.connect(_on_animation_player_finished)


# 🎯 3. 【核心新增】：利用 _process 在编辑器里实现“所见即所得”
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		# 当你在右侧面板换图或改格子时，这里会实时帮你在场景里同步，不需要运行游戏！
		if head_sprite and head_sprite.texture != head_texture:
			head_sprite.texture = head_texture
			head_sprite.hframes = head_hframes
			head_sprite.vframes = head_vframes
			head_sprite.visible = (head_texture != null)
			
		if body_sprite and body_sprite.texture != body_texture:
			body_sprite.texture = body_texture
			body_sprite.hframes = body_hframes
			body_sprite.vframes = body_vframes


func init_visual(
	h_tex: Texture2D, h_h: int, h_v: int,
	b_tex: Texture2D, b_h: int, b_v: int,
	lib: AnimationLibrary
) -> void:
	# 1. 初始化头部贴图与切片
	if head_sprite:
		head_sprite.texture = h_tex
		head_sprite.hframes = h_h 
		head_sprite.vframes = h_v 
		head_sprite.visible = (h_tex != null)

	# 2. 初始化身体（或足球）贴图与切片
	if body_sprite:
		body_sprite.texture = b_tex
		body_sprite.hframes = b_h 
		body_sprite.vframes = b_v 

	# 3. 注入动画库 (只有在游戏实际运行、或者编辑器里库不为空时注入)
	if anim_player and lib:
		if anim_player.has_animation_library("global"):
			anim_player.remove_animation_library("global")
		anim_player.add_animation_library("global", lib)


# --- 【统一控制接口】 ---
func set_facing(direction: float):
	if direction > 0: scale.x = 1
	elif direction < 0: scale.x = -1

func play_anim(anim_name: String) -> void:
	var full_name = "global/" + anim_name
	if anim_player and anim_player.has_animation(full_name):
		anim_player.play(full_name)

func update_z_height(z_height: float) -> void:
	if height_anchor:
		height_anchor.position.y = -z_height

func _on_animation_player_finished(full_name: String) -> void:
	var clean_name = full_name.replace("global/", "")
	animation_finished_custom.emit(clean_name)
