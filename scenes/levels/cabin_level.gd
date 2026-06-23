extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu

const LEVEL_1_SCENE := "res://scenes/levels/level_1.tscn"
const LEVEL_1_SPAWN_MARKER := "CabinExitSpawn"
const CABIN_DIALOG_ID := "cabin_first_visit"
const CABIN_DIALOG := [
	{"speaker": "GAROTA", "text": "Essa cabana está vazia..."},
	{"speaker": "GAROTA", "text": "Mas tem comida fresca aqui. Alguém passou por perto há pouco tempo."},
	{"speaker": "GAROTA", "text": "Não é a casa da vovó. Melhor voltar para a trilha."},
]

var _is_transitioning := false

func _ready() -> void:
	_interact_prompt.visible = false
	_door_trigger.monitoring = true
	call_deferred("_start_cabin_dialog")

func _process(_delta: float) -> void:
	if _is_transitioning or _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = _door_trigger.overlaps_body(_player)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_modal_active():
		return

	if event.is_action_pressed("ui_cancel"):
		if !_pause_menu.visible:
			_pause_menu.open_menu()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _door_trigger.overlaps_body(_player):
		_is_transitioning = true
		_interact_prompt.visible = false
		get_node("/root/SceneTransition").transition_to(LEVEL_1_SCENE, LEVEL_1_SPAWN_MARKER)


func _start_cabin_dialog() -> void:
	var game_state := get_node("/root/GameState")
	if game_state.has_seen_dialog(CABIN_DIALOG_ID):
		return

	game_state.mark_dialog_seen(CABIN_DIALOG_ID)
	await get_node("/root/DialogManager").start_dialog(CABIN_DIALOG)

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
