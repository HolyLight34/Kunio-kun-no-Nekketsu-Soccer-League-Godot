class_name BallReceiverArea
extends Area2D

## 角色用于检测可交互足球的 XY 接触区域。
##
## 该组件只负责检测角色与足球之间的进入和退出。
## 当足球进入区域时，将所属角色注册到足球的接触候选列表；
## 当足球离开区域时，将所属角色从候选列表中移除。
##
## Z 轴重叠、接触优先级以及最终接触角色的选择，
## 均由 Ball 负责。


## 当前区域所属的角色。
var _player: Player


func _ready() -> void:
	_player = owner as Player


## 启用足球接触检测。
func enable() -> void:
	monitoring = true


## 禁用足球接触检测。
func disable() -> void:
	monitoring = false


## 足球进入角色的 XY 接触区域时，
## 将当前角色注册到足球的接触候选列表。
func _on_area_entered(area: Area2D) -> void:
	var ball := area.owner as Ball

	if ball == null:
		return

	ball.register_receiver(_player)


## 足球离开角色的 XY 接触区域时，
## 将当前角色从足球的接触候选列表中移除。
func _on_area_exited(area: Area2D) -> void:
	var ball := area.owner as Ball

	if ball == null:
		return
	print("UNREGISTER: ", _player)
	ball.unregister_receiver(_player)
