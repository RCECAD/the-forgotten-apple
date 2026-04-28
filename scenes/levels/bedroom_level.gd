extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu

var _is_transitioning := false

func _ready() -> void:
	_interact_prompt.visible = false
	_door_trigger.monitoring = true

func _process(_delta: float) -> void:
	if _is_transitioning:
		_interact_prompt.visible = false
		return

	var player_in_door := _door_trigger.overlaps_body(_player)
	_interact_prompt.visible = player_in_door

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if event.is_action_pressed("ui_cancel"):
		if !_pause_menu.visible:
			_pause_menu.open_menu()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _door_trigger.overlaps_body(_player):
		_is_transitioning = true
		_interact_prompt.visible = false
		get_node("/root/SceneTransition").transition_to("res://scenes/levels/kitchen_level.tscn")
