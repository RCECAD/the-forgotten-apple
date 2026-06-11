extends Node

const DEFAULT_MAX_HEALTH := 3

var max_health := DEFAULT_MAX_HEALTH
var health := DEFAULT_MAX_HEALTH

func reset_player_health() -> void:
	max_health = DEFAULT_MAX_HEALTH
	health = max_health

func set_player_health(current_health: int, current_max_health: int) -> void:
	max_health = maxi(current_max_health, 1)
	health = clampi(current_health, 0, max_health)
