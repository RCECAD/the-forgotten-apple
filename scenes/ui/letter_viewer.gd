extends Node

const LETTER_VIEWER_SCENE := preload("res://scenes/ui/letter_viewer.tscn")

var is_letter_open := false
var _viewer: CanvasLayer

func open_letter() -> void:
	if is_letter_open:
		return
	if get_node("/root/DialogManager").is_dialog_active:
		return

	is_letter_open = true
	_set_player_input_enabled(false)
	_viewer = LETTER_VIEWER_SCENE.instantiate() as CanvasLayer
	get_tree().root.add_child(_viewer)
	await _viewer.letter_closed

	if is_instance_valid(_viewer):
		_viewer.queue_free()
	_viewer = null
	is_letter_open = false
	_set_player_input_enabled(true)

func _set_player_input_enabled(enabled: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(enabled)
