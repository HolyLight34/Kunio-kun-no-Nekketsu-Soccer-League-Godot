
class_name PlayerContactHandler
extends Node


# ==============================================================================
# 依赖与接触状态
# ==============================================================================

## 负责组装本组件的角色。
var player: Player

var _target_player: Player = null

enum PlayerContactAction {
	NORMAL_ATTACK,
	SPECIAL_ATTACK,
	TEAM_UP,
	SLIDE_TACKLE,
}

var _action_window_active: bool = false
var current_action: Types.PlayerContactAction


func open_action_window(action: Types.PlayerContactAction) -> void:
	current_action = action
	_action_window_active = true


func close_action_window() -> void:
	_action_window_active = false
# ==============================================================================
# 初始化
# ==============================================================================

## 由 Player 统一初始化。
func initialize(owner_player: Player) -> void:
	player = owner_player


# ==============================================================================
# 接触状态
# ==============================================================================

## 由 Player 的 HitBox 信号连接调用。
func _on_contact_started(target: Node) -> void:
	if target is not Player:
		return

	_target_player = target as Player
	
func _on_contact_ended(target: Node) -> void:
	if target != _target_player:
		return

	_target_player = null


# ==============================================================================
# 逻辑步
# ==============================================================================

## 由统一逻辑步调度器调用。
##
## 接触持续期间反复尝试处理。
## 条件不满足时等待；成功响应后不重复执行。
func logic_tick() -> void:
	if _target_player == null:
		return
	_handle_contact()


# ==============================================================================
# 足球接触处理
# ==============================================================================
func _handle_contact() -> void:
	if not _action_window_active:
		return
	match current_action:
		PlayerContactAction.NORMAL_ATTACK:
			_target_player.resolve_strike(_create_strike_data(2))
		PlayerContactAction.SPECIAL_ATTACK:
			pass
		PlayerContactAction.TEAM_UP:
			pass
		PlayerContactAction.SLIDE_TACKLE:
			_target_player.resolve_tackle(_create_tackle_data())
			pass
func _create_strike_data(
	damage: int
) -> StrikeData:
	var data := StrikeData.new()

	data.attacker = player
	data.attack_direction = player.facing_direction
	data.endurance = player.endurance
	data.damage = damage

	return data

func _create_tackle_data() -> TackleData:
	var data := TackleData.new()
	data.attacker = player
	data.attack_direction = player.facing_direction
	return data
