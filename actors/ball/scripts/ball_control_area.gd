## 足球普通控制交互区域。
##
## 负责检测 Player 是否与 Ball 形成有效的普通控球接触，
## 并将检测结果通过信号通知所属 Ball。
##
## --------------------------------------------------------------------------
## 检测方式
## --------------------------------------------------------------------------
##
## Godot Area2D 只负责筛选 XY 平面的候选 Player：
##
##     area_entered
##         ↓
##     保存 Player
##
##     area_exited
##         ↓
##     移除 Player
##
## 真正的有效接触判断发生在统一 Logic Tick 中。
##
## 每个 Logic Tick：
##
##     当前存在 XY 候选 Player
##         ↓
##     检查 Player / Ball 的 Z 轴重叠
##         ↓
##     XYZ 均满足
##         ↓
##     player_detected.emit(player)
##
## --------------------------------------------------------------------------
## 为什么持续检测
## --------------------------------------------------------------------------
##
## 本组件不把接触设计成一次性的“进入事件”。
##
## 即使 Player 和 Ball 一直没有离开 XY 范围，
## 游戏规则也可能在后续 Logic Tick 中发生变化。
##
## 例如：
##
##     原地挑球
##         ↓
##     Player 与 Ball 已经重叠
##         ↓
##     当前特殊规则禁止普通控球
##         ↓
##     足球第一次反弹
##         ↓
##     特殊规则解除
##         ↓
##     下一 Logic Tick 重新检查现有接触
##
## 因此本组件只报告：
##
##     “这个 Logic Tick，Player 与 Ball 当前形成有效 XYZ 接触。”
##
## 至于这次接触是否真正产生球权变化，
## 由 Ball 根据当前游戏规则决定。
##
## --------------------------------------------------------------------------
## 职责
## --------------------------------------------------------------------------
##
## 本组件负责：
## - 使用 Area2D 筛选 XY 候选 Player。
## - 保存当前处于 XY 范围内的 Player。
## - 每个 Logic Tick 检查 Z 轴重叠。
## - 通过 player_detected 报告当前有效接触。
## - 控制本区域是否参与普通足球交互。
##
## 本组件不负责：
## - 判断 Ball 是否允许被控制。
## - 判断原地挑球等特殊规则。
## - 判断 Ball 应该进入什么状态。
## - 判断 Player 应该进入什么状态。
## - 修改 Ball.carrier。
## - 修改 Ball 或 Player 的状态。
##
## Player 和 Ball 分别拥有自己的 Z 高度和碰撞高度。
## 本组件只读取这些公开信息完成 Z 轴碰撞判断。
##
## --------------------------------------------------------------------------
## 当前限制
## --------------------------------------------------------------------------
##
## 当前版本只保存一个 Player。
##
## FC 原版存在固定角色槽位扫描顺序。
## 后续实现多人同时接触时，
## 应将单个 Player 扩展为候选集合，
## 并按照 FC 槽位顺序检查。
##
class_name BallControlArea
extends Area2D


# ==============================================================================
# 信号
# ==============================================================================

## 当前 Logic Tick 中，
## Player 与 Ball 满足有效 XYZ 接触条件时发送。
##
## 注意：
##
## 只要双方持续满足接触条件，
## 本信号可能连续多个 Logic Tick 发送。
##
## 是否真正执行控球行为由 Ball 决定。
signal player_detected(player: Player)


# ==============================================================================
# 当前 XY 候选
# ==============================================================================

## 当前处于 Ball XY 控制范围内的 Player。
##
## 这里只表示 XY 平面发生重叠，
## 不代表 Z 轴也满足接触条件。
var _player_in_range: Player = null


# ==============================================================================
# 对外接口
# ==============================================================================

## 启用本区域参与普通足球交互。
##
## monitoring：
## 本 Area 可以主动检测 BallReceiverArea。
##
## monitorable：
## Player 的 BallReceiverArea 也可以检测本 Area。
func enable() -> void:
	monitoring = true
	monitorable = true


## 禁用本区域参与普通足球交互。
##
## 禁用后：
## - 不再主动检测 BallReceiverArea。
## - 也无法被 BallReceiverArea 检测。
## - 清除当前保存的 XY 候选。
func disable() -> void:
	monitoring = false
	monitorable = false

	_player_in_range = null


## 执行一次普通足球接触检测。
##
## 应由统一 FC Logic Tick 调用。
##
## Area2D 已经负责筛选 XY 范围，
## 因此这里只需要：
##
## 1. 确认存在候选 Player。
## 2. 检查 Z 轴是否重叠。
## 3. 满足条件则报告当前接触。
##
## 本方法不会记忆“上一 Tick 是否已经接触”。
## 每个 Logic Tick 都独立判断当前接触状态。
func logic_tick() -> void:
	if not monitoring:
		return

	if _player_in_range == null:
		return

	if not _is_z_overlapping(_player_in_range):
		return

	player_detected.emit(_player_in_range)


# ==============================================================================
# XY 候选维护
# ==============================================================================

## BallReceiverArea 进入 Ball 的 XY 控制范围。
##
## 这里只记录 Player。
## 不在这里执行控球，也不在这里判断 Z 轴。
func _on_area_entered(area: Area2D) -> void:
	if not area is BallReceiverArea:
		return

	var ball_receiver_area := area as BallReceiverArea
	var player := ball_receiver_area.owner as Player

	if player == null:
		return

	_player_in_range = player


## BallReceiverArea 离开 Ball 的 XY 控制范围。
##
## 如果离开的正是当前保存的 Player，
## 清除候选。
func _on_area_exited(area: Area2D) -> void:
	if not area is BallReceiverArea:
		return

	var ball_receiver_area := area as BallReceiverArea
	var player := ball_receiver_area.owner as Player

	if player == null:
		return

	if player != _player_in_range:
		return

	_player_in_range = null


# ==============================================================================
# Z 轴碰撞判断
# ==============================================================================

## 判断 Player 与 Ball 当前是否发生 Z 轴重叠。
##
## FC：
##
##     ball_z < player_z + player_height
##
## 并且：
##
##     player_z < ball_z + ball_height
##
## Player / Ball 的碰撞高度由各自实体提供，
## 本组件不保存具体高度值。
func _is_z_overlapping(player: Player) -> bool:
	var ball := owner as Ball

	if ball == null:
		return false

	var ball_z := ball.get_z_height()
	var player_z := player.get_z_height()

	return (
		ball_z < player_z + player.get_collision_height()
		and
		player_z < ball_z + ball.get_collision_height()
	)
