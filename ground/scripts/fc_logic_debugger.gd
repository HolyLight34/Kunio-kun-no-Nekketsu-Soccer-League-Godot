
extends Control


@export var logic_clock: FCLogicClock


# ==============================================================================
# 节点引用
# ==============================================================================

@onready var physics_grid: GridContainer = \
	$PanelContainer/VBoxContainer/PhysicsGrid

@onready var frame_label: Label = \
	$PanelContainer/VBoxContainer/HeaderContainer/FrameLabel

@onready var status_label: Label = \
	$PanelContainer/VBoxContainer/HeaderContainer/StatusLabel

@onready var pause_button: Button = \
	$PanelContainer/VBoxContainer/ButtonContainer/PauseButton

@onready var step_button: Button = \
	$PanelContainer/VBoxContainer/ButtonContainer/StepButton

@onready var resume_button: Button = \
	$PanelContainer/VBoxContainer/ButtonContainer/ResumeButton


# ==============================================================================
# 数据
# ==============================================================================

## 通过节点名称保存对应的 Label 引用。
var _labels: Dictionary = {}


## 角色的 XYZ 坐标。
var player_position: Vector3 = Vector3.ZERO

## 角色的 XYZ 速度。
var player_velocity: Vector3 = Vector3.ZERO

## 足球的 XYZ 坐标。
var ball_position: Vector3 = Vector3.ZERO

## 足球的 XYZ 速度。
var ball_velocity: Vector3 = Vector3.ZERO


# ==============================================================================
# 生命周期
# ==============================================================================

func _ready() -> void:
	_initialize_labels()

	logic_clock.logic_tick.connect(
		refresh_frame_display
	)

	refresh_display()
	refresh_status()
	refresh_frame_display()


## 收集 PhysicsGrid 中的 Label。
func _initialize_labels() -> void:
	for child in physics_grid.get_children():
		if child is Label:
			_labels[child.name] = child


# ==============================================================================
# 公共接口
# ==============================================================================

## 设置角色和足球的物理数据。
func set_physics_data(
	new_player_position: Vector3,
	new_player_velocity: Vector3,
	new_ball_position: Vector3,
	new_ball_velocity: Vector3
) -> void:
	player_position = new_player_position
	player_velocity = new_player_velocity

	ball_position = new_ball_position
	ball_velocity = new_ball_velocity

	refresh_display()


# ==============================================================================
# 数据显示
# ==============================================================================

func refresh_display() -> void:
	# X 轴
	_labels[&"XPlayerPositionLabel"].text = \
		"%.4f" % player_position.x

	_labels[&"XPlayerVelocityLabel"].text = \
		"%+.4f" % player_velocity.x

	_labels[&"XBallPositionLabel"].text = \
		"%.4f" % ball_position.x

	_labels[&"XBallVelocityLabel"].text = \
		"%+.4f" % ball_velocity.x

	# Y 轴
	_labels[&"YPlayerPositionLabel"].text = \
		"%.4f" % player_position.y

	_labels[&"YPlayerVelocityLabel"].text = \
		"%+.4f" % player_velocity.y

	_labels[&"YBallPositionLabel"].text = \
		"%.4f" % ball_position.y

	_labels[&"YBallVelocityLabel"].text = \
		"%+.4f" % ball_velocity.y

	# Z 轴
	_labels[&"ZPlayerPositionLabel"].text = \
		"%.4f" % player_position.z

	_labels[&"ZPlayerVelocityLabel"].text = \
		"%+.4f" % player_velocity.z

	_labels[&"ZBallPositionLabel"].text = \
		"%.4f" % ball_position.z

	_labels[&"ZBallVelocityLabel"].text = \
		"%+.4f" % ball_velocity.z


## 更新逻辑帧编号。
func refresh_frame_display() -> void:
	frame_label.text = "Frame: %d" % logic_clock.logic_frame


## 更新运行状态。
func refresh_status() -> void:
	if logic_clock.is_paused:
		status_label.text = "PAUSED"
	else:
		status_label.text = "RUNNING"


# ==============================================================================
# 按钮回调
# ==============================================================================

func _on_pause_button_pressed() -> void:
	logic_clock.pause()
	refresh_status()


func _on_step_button_pressed() -> void:
	logic_clock.step()


func _on_resume_button_pressed() -> void:
	logic_clock.resume()
	refresh_status()
