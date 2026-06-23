extends Node

signal dialog_line_started(entry: Dictionary, index: int)

const DIALOG_BOX_SCENE := preload("res://scenes/ui/dialog_box.tscn")

var is_dialog_active: bool = false
var _dialog_box: CanvasLayer

func start_dialog(lines: Array, restore_player_input := true) -> void:
	if is_dialog_active or lines.is_empty():
		return
	if get_node("/root/InventoryManager").is_inventory_open:
		return
	if get_node("/root/LetterViewer").is_letter_open:
		return

	is_dialog_active = true
	_set_player_input_enabled(false)
	_dialog_box = DIALOG_BOX_SCENE.instantiate() as CanvasLayer
	get_tree().root.add_child(_dialog_box)
	_dialog_box.dialog_line_started.connect(_on_dialog_line_started)
	_dialog_box.call("show_dialog", lines)
	await _dialog_box.dialog_finished

	if is_instance_valid(_dialog_box):
		_dialog_box.queue_free()
	_dialog_box = null
	is_dialog_active = false
	if restore_player_input:
		_set_player_input_enabled(true)

func is_active() -> bool:
	return is_dialog_active

func _set_player_input_enabled(enabled: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(enabled)

func _on_dialog_line_started(entry: Dictionary, index: int) -> void:
	dialog_line_started.emit(entry, index)
