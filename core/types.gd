class_name Types
extends RefCounted

enum PlayerStateType {
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
	DIVING_HEADER,
	CRAWL,
	CRAWL_HORIZONTAL,
	CRAWL_ROLL,
	SPECIAL_DRIBBLE,
	BURST_ATTACK,
	ORDER,
} 
enum BallContactAction {
	KICK,
	PASS,
	SLIDE_TACKLE,
}

enum PlayerContactAction {
	NORMAL_ATTACK,
	SPECIAL_ATTACK,
	TEAM_UP,
	SLIDE_TACKLE,
}
## 队伍进攻方向。
enum TeamAttackDirection {
	LEFT,
	RIGHT,
}
enum ShotMode {
	NORMAL,    ## FC $80
	DOWNWARD,  ## FC $81
	UPWARD,    ## FC $82
}
enum Team {
	TEAM_1,
	TEAM_2,
}
# Types.gd
enum InputButtonType {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	A,
	B,
	START,
	SELECT,
}

enum PlayerCommandType {
	NONE,
	A,
	B,
	A_B,
	DOUBLE_TAP,
}
enum BallPossession {
	NONE,       # 当前无人持球
	MYSELF,     # 自己持球
	TEAMMATE,   # 队友持球
	OPPONENT,   # 对手持球
}
enum BaseGroundType {
	NORMAL,
	SAND,
}
enum GroundEffect {
	NONE,
	PUDDLE,
	SWAMP,
}
