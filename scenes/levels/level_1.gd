extends Node2D

@onready var _player: CharacterBody2D = $Ground/Player
@onready var _camera: Camera2D = $Camera2D
@onready var _background0: Sprite2D = $Background0

const CAMERA_SMOOTH_SPEED := 4.0
const BG0_Z_INDEX := -30

var _camera_start_x: float
var _camera_start_y: float
var _follow_player := false
var _background0_offset: Vector2

func _ready() -> void:
	_camera.make_current()
	_camera_start_x = _camera.global_position.x
	_camera_start_y = _camera.global_position.y
	_background0_offset = _background0.global_position - _camera.global_position
	_background0.z_index = BG0_Z_INDEX

func _process(_delta: float) -> void:
	if !_follow_player and _player.global_position.x > _camera_start_x:
		_follow_player = true

	var target_x := _camera_start_x
	if _follow_player:
		target_x = _player.global_position.x

	var smooth_factor := 1.0 - exp(-CAMERA_SMOOTH_SPEED * _delta)
	_camera.global_position.x = lerp(_camera.global_position.x, target_x, smooth_factor)
	_camera.global_position.y = _camera_start_y
	_background0.global_position = _camera.global_position + _background0_offset
