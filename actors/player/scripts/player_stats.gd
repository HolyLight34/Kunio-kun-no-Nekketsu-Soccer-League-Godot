class_name PlayerStats # 必须定义类名，才能在创建资源时找到它
extends Resource

@export_group("基本信息")
@export var player_name: String = "球员A"
#@export var portrait: Texture2D # 球员头像

@export_group("能力数值")
@export var speed: float = 200.0
@export var kick_power: float = 50.0
#@export var stamina: int = 100

@export_group("视觉素材")
#@export var sprite_frames: SpriteFrames # 该球员专属的动画集
# 存放整张序列图
@export var sprite_sheet: Texture2D 

# 如果不同球员的帧数不同，也可以定义在这里
@export var h_frames: int = 4  # 水平帧数
@export var v_frames: int = 6  # 垂直帧数
enum Controller {
	P1,
	P2,
	CPU,
}

@export var controlled_by: Controller
