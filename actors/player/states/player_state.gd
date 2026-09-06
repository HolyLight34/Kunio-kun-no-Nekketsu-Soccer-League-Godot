class_name PlayerState
extends EntityState # 继承自你的通用 State

enum State {
	IDLE,
	WALK,
	RUN,
	BRAKE,
	JUMP,
	ACTION_A,
	ACTION_B,
	HURT,
	LAND,
	KICK,
	ELBOW_STRIKE,
	PASS,
	TACKLE,
} 
@export_group("State Info")
@export var state: State


@export_group("Capabilities")
#@export var can_move: bool = true

@export_group("Timing & Frame Data")
#@export var has_windup: bool = true        # 是否具备前摇硬直
		 # 前摇延迟 Tick 数（如 3 代表 10 帧）
# 🌟 定义转向策略枚举
enum FacingMode {
	FOLLOW_INPUT, # 自动跟随玩家输入的方向转向（如 Walk, Idle）
	LOCK,         # 完全锁定方向，拒绝任何转向（如 Attack 前摇、Shoot、Dash）
	MANUAL        # 由状态内部逻辑在特定的帧/代码中手动控制转向
}

@export_group("Facing Control")
## 该状态下的转向策略
@export var facing_mode: FacingMode = FacingMode.FOLLOW_INPUT
# 【核心变量】将通用的 actor 转换为具体的“球员”类型，方便调用球员特有的功能（如血量、速度）
# get: 语法意味着每次使用 player 变量时，都会实时执行后面的转换逻辑
var player: Player:
	get:
		return actor as Player
# 默认所有状态都允许转身
func handle_contact(_hurt_box: HurtBox) -> void:
	pass
func _prepare_hit_box(
	attack_type: Types.AttackType,
	damage: float,
	knockback_speed: float,
	z_velocity: float
) -> void:
	var hit_info := HitInfo.new()
	hit_info.attack_type = attack_type
	hit_info.damage = damage
	hit_info.attack_direction = player.facing_direction
	hit_info.knockback_speed = knockback_speed
	hit_info.z_velocity = z_velocity
	player.hit_box.hit_info = hit_info
