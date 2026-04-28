extends Node2D

@onready var _player: CharacterBody2D = $Ground/Player
@onready var _camera: Camera2D = $Camera2D
@onready var _background0: Sprite2D = $Background0
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _wind_sound: AudioStreamPlayer = $WindSound
@onready var _music_sound: AudioStreamPlayer = $MusicSound

const CAMERA_SMOOTH_SPEED := 6.0
const BG0_Z_INDEX := -30

var _camera_start_x: float
var _camera_start_y: float
var _follow_player := false
var _background0_offset: Vector2
var _music_timer: SceneTreeTimer

func _ready() -> void:
	_camera.make_current()
	_camera_start_x = _camera.global_position.x
	_camera_start_y = _camera.global_position.y
	_background0_offset = _background0.global_position - _camera.global_position
	_background0.z_index = BG0_Z_INDEX
	_wind_sound.play()
	get_node("/root/GameSettings").call("apply_audio")
	_music_timer = get_tree().create_timer(5.0)
	_music_timer.timeout.connect(_play_music)

func _process(_delta: float) -> void:
	if !_follow_player and _player.global_position.x > _camera_start_x:
		_follow_player = true

	var target_x := _camera_start_x
	if _follow_player:
		target_x = round(_player.global_position.x)

	var smooth_factor := 1.0 - exp(-CAMERA_SMOOTH_SPEED * _delta)
	_camera.global_position.x = lerp(_camera.global_position.x, target_x, smooth_factor)
	_camera.global_position.y = _camera_start_y
	_background0.global_position = (_camera.global_position + _background0_offset).round()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and !_pause_menu.visible:
		_pause_menu.open_menu()
		get_viewport().set_input_as_handled()

func _play_music() -> void:
	if !is_inside_tree():
		return
	_music_sound.play()
