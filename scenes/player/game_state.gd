extends Node

const DEFAULT_MAX_HEALTH := 3

var max_health := DEFAULT_MAX_HEALTH
var health := DEFAULT_MAX_HEALTH
var intro_dialog_seen := false
var white_flower_quest_started := false
var has_white_flower := false
var gave_white_flower_to_npc := false

func reset_player_health() -> void:
	max_health = DEFAULT_MAX_HEALTH
	health = max_health

func reset_narrative_progress() -> void:
	intro_dialog_seen = false
	white_flower_quest_started = false
	has_white_flower = false
	gave_white_flower_to_npc = false

func set_player_health(current_health: int, current_max_health: int) -> void:
	max_health = maxi(current_max_health, 1)
	health = clampi(current_health, 0, max_health)
