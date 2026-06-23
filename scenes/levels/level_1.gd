extends Node2D

@onready var _player: CharacterBody2D = $Ground/Player
@onready var _camera: Camera2D = $Camera2D
@onready var _background0: Sprite2D = $Background0
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _wind_sound: AudioStreamPlayer = $WindSound
@onready var _music_sound: AudioStreamPlayer = $MusicSound
@onready var _cabin_trigger: Area2D = $CabinDoorTrigger
@onready var _tent_trigger: Area2D = $TentDoorTrigger
@onready var _interact_prompt: Label = $Ground/Player/InteractPrompt
@onready var _bees: Array[Node] = [
	$BeeEnemy,
	$BeeEnemy2,
	$BeeEnemy3,
	$BeeEnemy4,
	$BeeEnemy5,
	$BeeEnemy6,
]

const CAMERA_SMOOTH_SPEED := 6.0
const BG0_Z_INDEX := -30
const CABIN_LEVEL_SCENE := "res://scenes/levels/cabin_level.tscn"
const TEND_LEVEL_SCENE := "res://scenes/levels/tend_level.tscn"
const HOUSE_EXIT_SPAWN_MARKER := "HouseExitSpawn"
const BEE_BUZZ_RADIUS := 420.0
const LEVEL_1_INTRO_DIALOG_ID := "level_1_intro"
const LEVEL_1_INTRO_DIALOG := [
	{"speaker": "GAROTA", "text": "A floresta parece bem maior daqui de fora."},
	{"speaker": "GAROTA", "text": "A vovó não teria entrado tão longe sem avisar... teria?"},
	{"speaker": "GAROTA", "text": "Vou procurar com calma. Qualquer sinal dela já ajuda."},
]

var _camera_start_x: float
var _camera_start_y: float
var _follow_player := false
var _background0_offset: Vector2
var _music_timer: SceneTreeTimer
var _is_transitioning := false

func _ready() -> void:
	_camera.make_current()
	_camera_start_x = _camera.global_position.x
	_camera_start_y = _camera.global_position.y
	_background0_offset = _background0.global_position - _camera.global_position
	_background0.z_index = BG0_Z_INDEX
	_interact_prompt.visible = false
	_cabin_trigger.monitoring = true
	_tent_trigger.monitoring = true
	_apply_spawn_marker()
	_update_bee_buzz_audio()
	_wind_sound.play()
	get_node("/root/GameSettings").call("apply_audio")
	_music_timer = get_tree().create_timer(5.0)
	_music_timer.timeout.connect(_play_music)
	call_deferred("_start_level_intro_dialog")

func _process(_delta: float) -> void:
	if _is_transitioning or _is_modal_active():
		_interact_prompt.visible = false
		return

	if _tent_trigger.overlaps_body(_player):
		_go_to_tent_cutscene()
		return

	var can_interact := _cabin_trigger.overlaps_body(_player)
	_interact_prompt.visible = can_interact
	_update_bee_buzz_audio()

	if !_follow_player and _player.global_position.x > _camera_start_x:
		_follow_player = true

	var target_x := _camera_start_x
	var target_y := _camera_start_y
	if _follow_player:
		target_x = round(_player.global_position.x)
		target_y = round(_player.global_position.y)

	var smooth_factor := 1.0 - exp(-CAMERA_SMOOTH_SPEED * _delta)
	_camera.global_position.x = lerp(_camera.global_position.x, target_x, smooth_factor)
	_camera.global_position.y = lerp(_camera.global_position.y, target_y, smooth_factor)
	_background0.global_position = (_camera.global_position + _background0_offset).round()

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_modal_active():
		return

	if event.is_action_pressed("ui_cancel") and !_pause_menu.visible:
		_pause_menu.open_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _cabin_trigger.overlaps_body(_player):
		_is_transitioning = true
		_interact_prompt.visible = false
		get_node("/root/SceneTransition").transition_to(CABIN_LEVEL_SCENE)

func _go_to_tent_cutscene() -> void:
	_is_transitioning = true
	_interact_prompt.visible = false
	get_node("/root/SceneTransition").transition_to(TEND_LEVEL_SCENE)

func _play_music() -> void:
	if !is_inside_tree():
		return
	_music_sound.play()

func _apply_spawn_marker() -> void:
	var marker_name: String = get_node("/root/SceneTransition").consume_spawn_marker()
	if marker_name.is_empty():
		return

	var spawn_marker := get_node_or_null(marker_name) as Marker2D
	if spawn_marker == null:
		return

	_player.global_position = spawn_marker.global_position
	_follow_player = marker_name != HOUSE_EXIT_SPAWN_MARKER
	if _follow_player:
		_camera.global_position.x = round(_player.global_position.x)
		_camera.global_position.y = round(_player.global_position.y)
	else:
		_camera.global_position.x = _camera_start_x
		_camera.global_position.y = _camera_start_y
	_background0.global_position = (_camera.global_position + _background0_offset).round()

func _update_bee_buzz_audio() -> void:
	for bee in _bees:
		bee.set("buzz_enabled", bee.global_position.distance_to(_player.global_position) <= BEE_BUZZ_RADIUS)


func _start_level_intro_dialog() -> void:
	var game_state := get_node("/root/GameState")
	if game_state.has_seen_dialog(LEVEL_1_INTRO_DIALOG_ID):
		return

	game_state.mark_dialog_seen(LEVEL_1_INTRO_DIALOG_ID)
	await get_node("/root/DialogManager").start_dialog(LEVEL_1_INTRO_DIALOG)

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
