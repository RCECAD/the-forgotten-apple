extends Node

const DEFAULT_MAX_HEALTH := 3

var max_health := DEFAULT_MAX_HEALTH
var health := DEFAULT_MAX_HEALTH
var intro_dialog_seen := false
var white_flower_quest_started := false
var has_white_flower := false
var gave_white_flower_to_npc := false

var collected_collectibles: Dictionary = {}

func reset_player_health() -> void:
	max_health = DEFAULT_MAX_HEALTH
	health = max_health

func reset_narrative_progress() -> void:
	intro_dialog_seen = false
	collected_collectibles.clear()
	white_flower_quest_started = false
	has_white_flower = false
	gave_white_flower_to_npc = false

func reset_white_flower_after_death() -> void:
	has_white_flower = false

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
