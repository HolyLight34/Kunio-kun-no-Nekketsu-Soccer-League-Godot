## 角色足球接收区域。
##
## 负责检测 Ball 是否与 Player 形成有效的普通足球接收接触，
## 并将检测结果通过信号通知所属 Player。
##
## ------------------------------------------------------------------------------
## 检测方式
## ------------------------------------------------------------------------------
##
## Godot Area2D 只负责筛选 XY 平面的候选 Ball：
##
##     area_entered
##         ↓
##     保存 Ball
##
##     area_exited
##         ↓
##     移除 Ball
##
## 真正的有效接触判断发生在统一 Logic Tick 中。
##
## 每个 Logic Tick：
##
##     当前存在 XY 候选 Ball
##         ↓
##     检查 Player / Ball 的 Z 轴重叠
##         ↓
##     XYZ 均满足
##         ↓
##     ball_detected.emit(ball)
##
## 本组件不会记录“上一 Tick 是否已经接触”。
##
## 只要 Player 与 Ball 当前仍然满足有效接触条件，
## 每个 Logic Tick 都可以重新发送 ball_detected。
##
## 这样即使双方没有离开 XY 范围，
## 当游戏规则发生变化时，
## Player 仍然可以在新的 Logic Tick 中重新处理当前接触。
##
## ------------------------------------------------------------------------------
## 职责
## ------------------------------------------------------------------------------
##
## 本组件负责：
## - 使用 Area2D 筛选 XY 候选 Ball。
## - 保存当前处于 XY 范围内的 Ball。
## - 每个 Logic Tick 检查双方的 Z 轴重叠。
## - 通过 ball_detected 信号报告当前有效接触。
## - 控制自身是否参与普通足球接收交互。
##
## 本组件不负责：
## - 判断 Player 当前是否应该接球。
## - 判断地面接球、胸停等具体行为。
## - 判断 Player 应该进入什么状态。
## - 判断 Ball 应该进入什么状态。
## - 修改 Player 或 Ball 的状态。
## - 修改 Ball 的 carrier。
##
## Player 和 Ball 分别拥有自己的 Z 高度与碰撞高度。
## 本组件只读取这些公开信息完成 Z 轴重叠判断。
##
## 是否允许 Player 参与普通足球接收交互，
## 由 Player 当前状态通过 enable() / disable() 控制。
##
## 当前版本只处理一个 Ball。
class_name BallReceiverArea
extends Area2D


# ==============================================================================
# 信号
# ==============================================================================

## 当前 Logic Tick 中，
## Ball 与 Player 满足有效 XYZ 接触条件时发送。
##
## 注意：
##
## 只要双方持续满足接触条件，
## 本信号可能连续多个 Logic Tick 发送。
##
## 是否真正执行接球行为由 Player 决定。
signal ball_detected(ball: Ball)


# ==============================================================================
# 当前 XY 候选
# ==============================================================================

## 当前处于 Player XY 接收范围内的 Ball。
##
## 这里只表示 XY 平面已经发生重叠，
## 不表示 Z 轴已经满足接触条件。
var _ball_in_range: Ball = null


# ==============================================================================
# 对外接口
# ==============================================================================

## 启用本区域参与普通足球接收交互。
##
## 启用后：
## - 本区域可以主动检测 BallControlArea。
## - 本区域也可以被 BallControlArea 检测。
func enable() -> void:
	monitoring = true
	monitorable = true


## 禁用本区域参与普通足球接收交互。
##
## 禁用后：
## - 本区域停止主动检测 BallControlArea。
## - 本区域无法被 BallControlArea 检测。
## - 清除当前保存的 XY 候选 Ball。
func disable() -> void:
	monitoring = false
	monitorable = false

	_clear_contact()


## 执行一次足球接收接触检测。
##
## 应由游戏统一 Logic Tick 调用。
##
## Area2D 已经负责筛选 XY 范围，
## 因此这里只需要：
##
## 1. 确认存在候选 Ball。
## 2. 检查 Z 轴是否重叠。
## 3. 满足条件则报告当前接触。
##
## 本方法不会记录上一 Tick 是否已经接触。
## 每个 Logic Tick 都独立判断当前接触状态。
func logic_tick() -> void:
	if not monitoring:
		return

	if _ball_in_range == null:
		return

	if not _is_z_overlapping(_ball_in_range):
		return

	ball_detected.emit(_ball_in_range)


# ==============================================================================
# XY 候选维护
# ==============================================================================

## BallControlArea 进入 Player 的 XY 接收范围。
##
## 这里只记录 Ball。
##
## 不在这里执行接球，
## 也不在这里判断 Z 轴。
func _on_area_entered(area: Area2D) -> void:
	if not area is BallControlArea:
		return

	var ball_control_area := area as BallControlArea
	var ball := ball_control_area.owner as Ball

	if ball == null:
		return

	_ball_in_range = ball


## BallControlArea 离开 Player 的 XY 接收范围。
##
## 如果离开的正是当前保存的 Ball，
## 清除当前候选。
func _on_area_exited(area: Area2D) -> void:
	if not area is BallControlArea:
		return

	var ball_control_area := area as BallControlArea
	var ball := ball_control_area.owner as Ball

	if ball == null:
		return

	if ball != _ball_in_range:
		return

	_clear_contact()


# ==============================================================================
# 内部方法
# ==============================================================================

## 清除当前保存的 Ball。
func _clear_contact() -> void:
	_ball_in_range = null


## 判断指定 Ball 与所属 Player 当前是否发生 Z 轴重叠。
##
## FC 的 Z 轴碰撞规则：
##
##     ball_z < player_z + player_height
##
## 并且：
##
##     player_z < ball_z + ball_height
##
## Player / Ball 的碰撞高度分别由各自实体提供。
##
## 本组件不保存 Player = 32、Ball = 16
## 这些实体自身的数据。
func _is_z_overlapping(ball: Ball) -> bool:
	var player := owner as Player

	if player == null:
		return false

	var player_z := player.get_z_height()
	var ball_z := ball.get_z_height()

	return (
		ball_z < player_z + player.get_collision_height()
		and
		player_z < ball_z + ball.get_collision_height()
	)
