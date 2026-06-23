extends Area2D

@export var collectible_id := "cabin_apple"
@export var heal_amount := 1

func _ready() -> void:
	var game_state := get_node("/root/GameState")

	if game_state.is_collectible_collected(collectible_id):
		queue_free()
		return

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"):
		return

	var game_state := get_node("/root/GameState")

	if !game_state.collect_collectible(collectible_id):
		queue_free()
		return

	if body.has_method("heal"):
		body.heal(heal_amount)

	queue_free()
