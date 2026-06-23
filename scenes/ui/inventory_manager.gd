extends Node

const INVENTORY_SCENE := preload("res://scenes/ui/inventory_ui.tscn")
const ITEM_COLLECTED_SCENE := preload("res://scenes/ui/item_collected.tscn")
const LETTER_TEXTURE := preload("res://assets/ui/letter.png")
const APPLE_TEXTURE := preload("res://assets/textures/items/apple.png")
const LETTER_ITEM_ID := "letter"
const WHITE_FLOWER_ITEM_ID := "white_flower"
const APPLE_ITEM_ID := "apple"

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

func remove_item(item_id: String) -> bool:
	if !_items.has(item_id):
		return false
	_items.erase(item_id)
	_refresh_ui()
	return true

func collect_item_with_presentation(
	item_id: String,
	display_name: String,
	texture: Texture2D,
	release_player_after := true
) -> bool:
	if has_item(item_id):
		return false

	_set_player_input_enabled(false)
	add_item(item_id)
	var presentation := ITEM_COLLECTED_SCENE.instantiate() as CanvasLayer
	presentation.set("item_name", display_name)
	presentation.set("item_texture", texture)
	get_tree().root.add_child(presentation)
	await presentation.presentation_finished
	if is_instance_valid(presentation):
		presentation.queue_free()
	if release_player_after:
		_set_player_input_enabled(true)
	return true

func collect_letter_with_presentation() -> bool:
	if has_item(LETTER_ITEM_ID):
		return false

	return await collect_item_with_presentation(LETTER_ITEM_ID, "Carta da vovó", LETTER_TEXTURE)

func collect_apple_with_presentation(release_player_after := true) -> bool:
	return await collect_item_with_presentation(
		APPLE_ITEM_ID,
		"Maçã",
		APPLE_TEXTURE,
		release_player_after
	)

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
	_inventory_ui.apple_selected.connect(_on_apple_selected)
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
		_inventory_ui.call(
			"set_items_visible",
			has_item(LETTER_ITEM_ID),
			has_item(WHITE_FLOWER_ITEM_ID),
			has_item(APPLE_ITEM_ID)
		)

func _on_letter_selected() -> void:
	close_inventory(false)
	await get_node("/root/LetterViewer").open_letter()

func _on_apple_selected() -> void:
	if !_use_apple():
		return
	_refresh_ui()

func _use_apple() -> bool:
	if !has_item(APPLE_ITEM_ID):
		return false

	var player := get_tree().get_first_node_in_group("player")
	if player == null or !player.has_method("heal"):
		return false

	var current_health := int(player.get("health"))
	var max_health := int(player.get("max_health"))
	if current_health >= max_health:
		return false

	player.call("heal", 1)
	remove_item(APPLE_ITEM_ID)
	return true

func _set_player_input_enabled(enabled: bool) -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(enabled)
