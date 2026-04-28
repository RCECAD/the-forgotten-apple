extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _door_trigger: Area2D = $DoorTrigger
@onready var _interact_prompt: Label = $Player/InteractPrompt

func _ready() -> void:
	_interact_prompt.visible = false
	_door_trigger.monitoring = true

func _process(_delta: float) -> void:
	var player_in_door := _door_trigger.overlaps_body(_player)
	_interact_prompt.visible = player_in_door

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_node("/root/SceneTransition").transition_to("res://scenes/ui/main_menu.tscn")
	elif event.is_action_pressed("interact") and _door_trigger.overlaps_body(_player):
		get_node("/root/SceneTransition").transition_to("res://scenes/levels/kitchen_level.tscn")
