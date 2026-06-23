extends Node2D

@onready var _player: CharacterBody2D = $Ground/Player
@onready var _camera: Camera2D = $Camera2D
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _interact_prompt: Label = $Ground/Player/InteractPrompt
@onready var _exit_trigger: Area2D = get_node_or_null("ExitTrigger") as Area2D

const CAMERA_SMOOTH_SPEED := 6.0
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

var _camera_start_x: float
var _camera_start_y: float
var _follow_player := false
var _is_transitioning := false

func _ready() -> void:
	_camera.make_current()
	_camera_start_x = _camera.global_position.x
	_camera_start_y = _camera.global_position.y
	_interact_prompt.visible = false
	if _exit_trigger != null:
		_exit_trigger.monitoring = true
	_apply_spawn_marker()

func _process(delta: float) -> void:
	if _is_transitioning or _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = _can_use_exit()
	_update_camera(delta)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_modal_active():
		return

	if event.is_action_pressed("ui_cancel") and !_pause_menu.visible:
		_pause_menu.open_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _can_use_exit():
		_finish_current_build()
		get_viewport().set_input_as_handled()

func _update_camera(delta: float) -> void:
	if !_follow_player and _player.global_position.x > _camera_start_x:
		_follow_player = true

	var target_x := _camera_start_x
	var target_y := _camera_start_y
	if _follow_player:
		target_x = round(_player.global_position.x)
		target_y = round(_player.global_position.y)

	var smooth_factor := 1.0 - exp(-CAMERA_SMOOTH_SPEED * delta)
	_camera.global_position.x = lerp(_camera.global_position.x, target_x, smooth_factor)
	_camera.global_position.y = lerp(_camera.global_position.y, target_y, smooth_factor)

func _apply_spawn_marker() -> void:
	var spawn_marker := get_node_or_null("CabinExitSpawn") as Marker2D
	if spawn_marker == null:
		return

	var marker_name: String = get_node("/root/SceneTransition").consume_spawn_marker()
	if marker_name != spawn_marker.name:
		return

	_player.global_position = spawn_marker.global_position
	_follow_player = true
	_camera.global_position.x = round(_player.global_position.x)
	_camera.global_position.y = round(_player.global_position.y)

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)

func _can_use_exit() -> bool:
	return _exit_trigger != null and _exit_trigger.overlaps_body(_player)

func _finish_current_build() -> void:
	_is_transitioning = true
	_interact_prompt.visible = false
	await get_node("/root/DialogManager").start_dialog([
		"A trilha continua adiante...",
		"Mas essa parte da floresta ainda esta sendo preparada."
	], false)
	get_node("/root/SceneTransition").transition_to(MAIN_MENU_SCENE)
