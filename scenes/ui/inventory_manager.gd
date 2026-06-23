extends Node

const INVENTORY_SCENE := preload("res://scenes/ui/inventory_ui.tscn")
const ITEM_COLLECTED_SCENE := preload("res://scenes/ui/item_collected.tscn")
const LETTER_ITEM_ID := "letter"

var is_inventory_open := false
var _items: Array[String] = []
var _inventory_ui: CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if is_inventory_open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_inventory()
		return
	if !event.is_action_pressed("inventory") or event.is_echo():
		return
	if get_node("/root/DialogManager").is_dialog_active:
		return
	if get_node("/root/LetterViewer").is_letter_open:
		return
	if get_tree().get_nodes_in_group("player").is_empty():
		return

	get_viewport().set_input_as_handled()
	if is_inventory_open:
		close_inventory()
	else:
		open_inventory()

func add_item(item_id: String) -> bool:
	if _items.has(item_id):
		return false
	_items.append(item_id)
	_refresh_ui()
	return true

func collect_letter_with_presentation() -> bool:
	if has_item(LETTER_ITEM_ID):
		return false

	_set_player_input_enabled(false)
	add_item(LETTER_ITEM_ID)
	var presentation := ITEM_COLLECTED_SCENE.instantiate() as CanvasLayer
	get_tree().root.add_child(presentation)
	await presentation.presentation_finished
	if is_instance_valid(presentation):
		presentation.queue_free()
	_set_player_input_enabled(true)
	return true

func has_item(item_id: String) -> bool:
	return _items.has(item_id)

func reset_inventory() -> void:
	_items.clear()
	if is_inventory_open:
		close_inventory()
	_refresh_ui()

func open_inventory() -> void:
	if is_inventory_open:
		return

	is_inventory_open = true
	_set_player_input_enabled(false)
	_inventory_ui = INVENTORY_SCENE.instantiate() as CanvasLayer
	get_tree().root.add_child(_inventory_ui)
	_inventory_ui.letter_selected.connect(_on_letter_selected)
	_refresh_ui()

func close_inventory(release_player: bool = true) -> void:
	if !is_inventory_open:
		return

	is_inventory_open = false
	if is_instance_valid(_inventory_ui):
		_inventory_ui.queue_free()
	_inventory_ui = null
	if release_player:
		_set_player_input_enabled(true)

func _refresh_ui() -> void:
	if is_instance_valid(_inventory_ui):
		_inventory_ui.call("set_letter_visible", has_item(LETTER_ITEM_ID))

func _on_letter_selected() -> void:
	close_inventory(false)
	await get_node("/root/LetterViewer").open_letter()

func _set_player_input_enabled(enabled: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(enabled)
