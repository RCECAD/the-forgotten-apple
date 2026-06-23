extends Area2D

@export var item_id := "white_flower"
@export var display_name := "Flor Branca"
@export var item_texture: Texture2D

var _player_inside: Node2D
var _is_collecting := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var game_state := get_node("/root/GameState")
	if bool(game_state.get("has_white_flower")) or bool(game_state.get("gave_white_flower_to_npc")):
		queue_free()

func can_interact() -> bool:
	return (
		_player_inside != null
		and !_is_collecting
		and !bool(get_node("/root/GameState").get("has_white_flower"))
		and !bool(get_node("/root/GameState").get("gave_white_flower_to_npc"))
		and !_is_modal_active()
	)

func collect() -> void:
	if !can_interact():
		return

	_is_collecting = true
	var game_state := get_node("/root/GameState")
	game_state.set("has_white_flower", true)
	await get_node("/root/InventoryManager").collect_item_with_presentation(
		item_id,
		display_name,
		item_texture
	)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = body

func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
