extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _furnace_trigger: Area2D = $FurnacePuzzleTrigger
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _music_sound: AudioStreamPlayer = $MusicSound
@onready var _camera: Camera2D = $Camera2D

const HIDDEN_ROOM_SCENE := "res://scenes/levels/hidden_room.tscn"

var _is_transitioning := false
var _is_solving_puzzle := false

func _ready() -> void:
	_camera.make_current()
	_interact_prompt.visible = false
	_furnace_trigger.monitoring = true
	get_node("/root/GameSettings").call("apply_audio")
	if _music_sound.stream != null:
		_music_sound.play()

	if bool(get_node("/root/GameState").get("furnace_puzzle_solved")):
		call_deferred("_go_to_hidden_room")

func _process(_delta: float) -> void:
	if _is_transitioning or _is_solving_puzzle or _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = _furnace_trigger.overlaps_body(_player)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_solving_puzzle:
		return

	if event.is_action_pressed("ui_cancel"):
		if !_pause_menu.visible:
			_pause_menu.open_menu()
			get_viewport().set_input_as_handled()
	elif _pause_menu.visible or _is_modal_active():
		return
	elif event.is_action_pressed("interact") and _furnace_trigger.overlaps_body(_player):
		get_viewport().set_input_as_handled()
		_solve_furnace_puzzle()

func _solve_furnace_puzzle() -> void:
	_is_solving_puzzle = true
	_interact_prompt.visible = false
	await get_node("/root/DialogManager").start_dialog([
		{"speaker": "GAROTA", "text": "O calor vem de dentro... como se o forno estivesse esperando."},
		"Ela empurra a porta pesada e entra no brilho baixo das brasas.",
		"Cinzas sobem, formando uma trilha que aponta para baixo."
	])

	get_node("/root/GameState").set("furnace_puzzle_solved", true)
	_go_to_hidden_room()

func _go_to_hidden_room() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	_interact_prompt.visible = false
	get_node("/root/SceneTransition").transition_to(HIDDEN_ROOM_SCENE)

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
