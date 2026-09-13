#extends Node
#class_name PlayerHurtResolver
#@export var player: Player
#func receive_hit(incoming: HitBox) -> void:
	#if not _can_receive_hit(incoming):
		#return
	#var source := incoming.source
	#var hit_info := incoming.hit_info
	#var hurt_data := _resolve_hurt_data(
		#source,
		#hit_info
	#)
	#if source is Player:
		#if _should_source_rebound(source, hit_info):
			#var source_rebound_data := _create_normal_hurt_data(
			#-hit_info.attack_direction
		#)
			#source.receive_hurt(source_rebound_data)
	#player.endurance -= hit_info.damage
	#player.receive_hurt(hurt_data)
#func _should_source_rebound(
	#source: Player,
	#hit_info: HitInfo
#) -> bool:
	#if hit_info.attack_type == Types.AttackType.SLIDE:
		#return false
#
	#return source.endurance + 8 < player.endurance
#
## ==============================================================================
## 10. 命中有效性
## ==============================================================================
#func _can_receive_hit(incoming: HitBox) -> bool:
	#if incoming.source is Player:
		#if incoming.source.team_id == player.team_id:
			#return false
	#match incoming.hit_info.attack_type:
		#Types.AttackType.KICK:
			#return false
		#Types.AttackType.SLIDE:
			#return is_running()
	#return true
#func is_running() -> bool:
	#return player.state_machine.current_state.name == "Run"
## ==============================================================================
## 11. 受击结果结算
## ==============================================================================
#func _resolve_hurt_data(
	#source: CharacterBody2D,
	#hit_info: HitInfo
#) -> HurtData:
	#match hit_info.attack_type:
		#Types.AttackType.SLIDE:
			#return _create_normal_hurt_data(
				#hit_info.attack_direction
			#)
		#Types.AttackType.BALL_HIT:
			#return _create_heavy_hurt_data(
			#hit_info,
			#Types.HurtType.HEAVY
		#)
		#Types.AttackType.ELBOW:
			#if source.endurance + 8 >= player.endurance:
				#return _create_heavy_hurt_data(
			#hit_info,
			#Types.HurtType.HEAVY
		#)
			#else :
				#return _create_normal_hurt_data(
		#hit_info.attack_direction
	#)
	#return null
## ==============================================================================
## 12. HurtData 创建
## ==============================================================================
#func _create_heavy_hurt_data(
	#hit_info: HitInfo,
	#hurt_type: Types.HurtType
#) -> HurtData:
	#var hurt_data := HurtData.new()
	#hurt_data.hurt_type = hurt_type
	#hurt_data.knockback_direction = (
		#_calculate_knockback_direction(
			#hit_info.attack_direction,
			#player.input_component.last_move_direction
		#)
	#)
	#hurt_data.knockback_speed = (
		#hit_info.horizontal_speed
	#)
	#hurt_data.z_velocity = (
		#hit_info.z_velocity
	#)
	#return hurt_data
#func _create_normal_hurt_data(
	#knockback_direction: Vector2
#) -> HurtData:
	#var hurt_data := HurtData.new()
	#hurt_data.hurt_type = Types.HurtType.NORMAL
	#hurt_data.knockback_direction = knockback_direction
	#hurt_data.knockback_speed = 6.0
	#return hurt_data
## ==============================================================================
## 13. 击退方向
## ==============================================================================
#func _calculate_knockback_direction(
	#attack_direction: Vector2,
	#last_move_direction: Vector2
#) -> Vector2:
	#if (
		#last_move_direction.x != 0.0
		#and last_move_direction.y != 0.0
	#):
		#var same_horizontal_direction := (
			#last_move_direction.x * attack_direction.x > 0.0
		#)
		#return (
			#last_move_direction
			#if same_horizontal_direction
			#else -last_move_direction
		#)
	#if last_move_direction.x != 0.0:
		#return attack_direction
	#if last_move_direction.y != 0.0:
		#return (
			#Vector2.UP
			#if attack_direction.x > 0.0
			#else Vector2.DOWN
		#)
	#return attack_direction
