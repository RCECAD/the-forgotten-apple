extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _wind_sound: AudioStreamPlayer = $WindSound
@onready var _music_sound: AudioStreamPlayer = $MusicSound

const CAMERA_SMOOTH_SPEED := 6.0
const MUSIC_DELAY := 5.0

var _camera_start_x: float
var _camera_start_y: float
var _follow_player := false
var _music_timer: SceneTreeTimer

func _ready() -> void:
	_camera.make_current()
	_camera_start_x = _camera.global_position.x
	_camera_start_y = _camera.global_position.y
	_wind_sound.play()
	get_node("/root/GameSettings").call("apply_audio")
	_music_timer = get_tree().create_timer(MUSIC_DELAY)
	_music_timer.timeout.connect(_play_music)

func _process(delta: float) -> void:
	if _is_modal_active():
		return

	_update_camera(delta)

func _unhandled_input(event: InputEvent) -> void:
	if _is_modal_active():
		return

	if event.is_action_pressed("ui_cancel") and !_pause_menu.visible:
		_pause_menu.open_menu()
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
	_camera.global_position = _camera.global_position.round()

func _play_music() -> void:
	if !is_inside_tree():
		return
	_music_sound.play()

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
