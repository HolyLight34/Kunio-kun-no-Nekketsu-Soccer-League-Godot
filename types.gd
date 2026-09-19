class_name Types
extends RefCounted

enum HurtType {
	NORMAL,
	HEAVY,
}

enum AttackType {
	KICK,
	PASS,
	SLIDE,
	ELBOW,
	BALL_HIT,
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
