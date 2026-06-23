extends Area2D

var _is_interacting := false
var _player_inside: Node2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func can_interact() -> bool:
	return (
		_player_inside != null
		and !_is_interacting
		and !get_node("/root/InventoryManager").has_item("letter")
		and !_is_modal_active()
	)

func trigger_sequence() -> void:
	if !can_interact():
		return

	_is_interacting = true
	await get_node("/root/DialogManager").start_dialog([
		"Receitas, lista de compras...",
		"Maçãs, farinha, canela...",
		"Espera. Essa nota parece recente."
	])
	await get_node("/root/InventoryManager").collect_letter_with_presentation()
	await get_node("/root/LetterViewer").open_letter()
	await get_node("/root/DialogManager").start_dialog([
		"Ela já devia ter voltado...",
		"Eu sei que ela pediu para eu ficar em casa, mas não posso simplesmente esperar.",
		"Preciso encontrá-la."
	])

	_is_interacting = false

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return
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
