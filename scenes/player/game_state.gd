extends Node

const DEFAULT_MAX_HEALTH := 3

var max_health := DEFAULT_MAX_HEALTH
var health := DEFAULT_MAX_HEALTH
var intro_dialog_seen := false

var collected_collectibles: Dictionary = {}

func reset_player_health() -> void:
	max_health = DEFAULT_MAX_HEALTH
	health = max_health

func reset_narrative_progress() -> void:
	intro_dialog_seen = false
	collected_collectibles.clear()

func set_player_health(current_health: int, current_max_health: int) -> void:
	max_health = maxi(current_max_health, 1)
	health = clampi(current_health, 0, max_health)

func is_collectible_collected(collectible_id: String) -> bool:
	return collected_collectibles.has(collectible_id)

func collect_collectible(collectible_id: String) -> bool:
	if collected_collectibles.has(collectible_id):
		return false

	collected_collectibles[collectible_id] = true
	return true
