class_name PlayerState
extends EntityState # 继承自你的通用 State

enum State {
	IDLE,
	WALK,
	RUN,
	BRAKE,
	JUMP,
	HURT,
	LAND,
	KICK,
	ELBOW_STRIKE,
	PASS,
	TACKLE,
	STATIONARY_FLICK,
	CHEST_TRAP,
	MOVING_FLICK,
	BICYCLE_KICK,
	REBOUND,
	KNOCKBACK,
	JUGGLE,
	AIR_KICK,
	DIVINGHEADER,
	CRAWL,
	CRAWL_HORIZONTAL,
	CRAWL_ROLL,
	SPECIAL_DRIBBLE,
	BURST_ATTACK,
} 
@export var player_state_id: State
enum FacingMode {
	FOLLOW_INPUT, # 自动跟随玩家输入的方向转向（如 Walk, Idle）
	LOCK,         # 完全锁定方向，拒绝任何转向（如 Attack 前摇、Shoot、Dash）
	MANUAL        # 由状态内部逻辑在特定的帧/代码中手动控制转向
}
func get_state_id() -> int:
	return player_state_id
@export_group("Facing Control")
## 该状态下的转向策略
@export var facing_mode: FacingMode = FacingMode.FOLLOW_INPUT
# 【核心变量】将通用的 actor 转换为具体的“球员”类型，方便调用球员特有的功能（如血量、速度）
# get: 语法意味着每次使用 player 变量时，都会实时执行后面的转换逻辑
var player: Player:
	get:
		return actor as Player
# 默认所有状态都允许转身
