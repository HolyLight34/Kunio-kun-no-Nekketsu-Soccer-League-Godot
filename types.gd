class_name Types
extends RefCounted

enum HitType {
	PASS,
	KICK,
	STRIKE,
	TACKLE,
	BALL_ATTACK,
	BALL,
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
