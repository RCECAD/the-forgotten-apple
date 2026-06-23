extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _interact_prompt: Control = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _letter_interactable: Area2D = $InteractableLetter

var _is_transitioning := false

func _ready() -> void:
	_interact_prompt.visible = false
	_door_trigger.monitoring = true

func _process(_delta: float) -> void:
	if _is_transitioning or _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = (
		_letter_interactable.call("can_interact")
		or _door_trigger.overlaps_body(_player)
	)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_modal_active():
		return

	if event.is_action_pressed("ui_cancel"):
		if !_pause_menu.visible:
			_pause_menu.open_menu()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _letter_interactable.call("can_interact"):
		get_viewport().set_input_as_handled()
		_letter_interactable.call("trigger_sequence")
	elif event.is_action_pressed("interact") and _door_trigger.overlaps_body(_player):
		_is_transitioning = true
		_interact_prompt.visible = false
		get_node("/root/SceneTransition").transition_to("res://scenes/levels/level_1.tscn")

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
