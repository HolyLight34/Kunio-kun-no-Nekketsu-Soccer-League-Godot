class_name Types
extends RefCounted

enum HitType {
	PASS,
	KICK,
	STRIKE,
	TACKLE,
	BALL_ATTACK,
}
enum AttackType {
	SLIDE,
	ELBOW,
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
