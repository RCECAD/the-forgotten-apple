extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _interact_prompt: Control = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu

var _is_transitioning := false

func _ready() -> void:
	_interact_prompt.visible = false
	_door_trigger.monitoring = true
	call_deferred("_start_intro_dialog")

func _process(_delta: float) -> void:
	if _is_transitioning or _is_modal_active():
		_interact_prompt.visible = false
		return

	var player_in_door := _door_trigger.overlaps_body(_player)
	_interact_prompt.visible = player_in_door

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
		get_node("/root/SceneTransition").transition_to("res://scenes/levels/kitchen_level.tscn")

func _start_intro_dialog() -> void:
	var game_state := get_node("/root/GameState")
	if bool(game_state.get("intro_dialog_seen")):
		return

	game_state.set("intro_dialog_seen", true)
	await get_node("/root/DialogManager").start_dialog([
		"Nossa... eu dormi demais.",
		"Era dia de limpar a casa e ajudar a vovó com a torta.",
		"Melhor eu me apressar antes que ela perceba que ainda não comecei."
	])

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
