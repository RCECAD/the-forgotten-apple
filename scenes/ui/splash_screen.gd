extends Control

@export_file("*.tscn") var loading_scene_path := "res://scenes/ui/loading_screen.tscn"
@export var hold_duration := 1.4
@export var fade_duration := 0.45

@onready var _content: Control = $Content

var _is_skipping := false

func _ready() -> void:
	_content.modulate.a = 0.0
	await _fade_content(1.0)
	await get_tree().create_timer(hold_duration).timeout
	_go_to_loading()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		_go_to_loading()

func _go_to_loading() -> void:
	if _is_skipping:
		return

	_is_skipping = true
	await _fade_content(0.0)
	get_node("/root/SceneTransition").transition_to(loading_scene_path)

func _fade_content(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_content, "modulate:a", alpha, fade_duration)
	await tween.finished
