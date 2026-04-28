class_name GameSettings

extends Node

signal settings_changed

const CONFIG_PATH := "user://settings.cfg"
const WINDOW_PRESETS := [
	Vector2i(640, 360),
	Vector2i(960, 540),
	Vector2i(1280, 720),
]

var music_volume_percent: float = 100.0
var enemy_volume_percent: float = 100.0
var effects_volume_percent: float = 100.0
var fullscreen_enabled := false
var window_preset_index := 2

func _ready() -> void:
	load_settings()
	apply_display()
	apply_audio()

func set_music_volume_percent(value: float) -> void:
	music_volume_percent = clampf(value, 0.0, 100.0)
	apply_audio()
	_save_settings()
	settings_changed.emit()

func set_enemy_volume_percent(value: float) -> void:
	enemy_volume_percent = clampf(value, 0.0, 100.0)
	apply_audio()
	_save_settings()
	settings_changed.emit()

func set_effects_volume_percent(value: float) -> void:
	effects_volume_percent = clampf(value, 0.0, 100.0)
	apply_audio()
	_save_settings()
	settings_changed.emit()

func set_fullscreen_enabled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	apply_display()
	_save_settings()
	settings_changed.emit()

func set_window_preset_index(index: int) -> void:
	window_preset_index = clampi(index, 0, WINDOW_PRESETS.size() - 1)
	apply_display()
	_save_settings()
	settings_changed.emit()

func apply_audio() -> void:
	_apply_group_volume("music", music_volume_percent)
	_apply_group_volume("enemies", enemy_volume_percent)
	_apply_group_volume("effects", effects_volume_percent)

func apply_display() -> void:
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(WINDOW_PRESETS[window_preset_index])

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return

	music_volume_percent = float(config.get_value("audio", "music_volume_percent", music_volume_percent))
	enemy_volume_percent = float(config.get_value("audio", "enemy_volume_percent", enemy_volume_percent))
	effects_volume_percent = float(config.get_value("audio", "effects_volume_percent", effects_volume_percent))
	fullscreen_enabled = bool(config.get_value("display", "fullscreen_enabled", fullscreen_enabled))
	window_preset_index = int(config.get_value("display", "window_preset_index", window_preset_index))
	window_preset_index = clampi(window_preset_index, 0, WINDOW_PRESETS.size() - 1)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume_percent", music_volume_percent)
	config.set_value("audio", "enemy_volume_percent", enemy_volume_percent)
	config.set_value("audio", "effects_volume_percent", effects_volume_percent)
	config.set_value("display", "fullscreen_enabled", fullscreen_enabled)
	config.set_value("display", "window_preset_index", window_preset_index)
	config.save(CONFIG_PATH)

func _apply_group_volume(group_name: String, percent: float) -> void:
	var volume_db := _percent_to_db(percent)
	for node in get_tree().get_nodes_in_group(group_name):
		if node is AudioStreamPlayer:
			(node as AudioStreamPlayer).volume_db = volume_db
		elif node is AudioStreamPlayer2D:
			(node as AudioStreamPlayer2D).volume_db = volume_db

func _percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return linear_to_db(percent / 100.0)

func get_music_volume_percent() -> float:
	return music_volume_percent

func get_enemy_volume_percent() -> float:
	return enemy_volume_percent

func get_effects_volume_percent() -> float:
	return effects_volume_percent

func is_fullscreen_enabled() -> bool:
	return fullscreen_enabled

func get_window_preset_index() -> int:
	return window_preset_index

func get_window_preset_label(index: int) -> String:
	var size: Vector2i = WINDOW_PRESETS[clampi(index, 0, WINDOW_PRESETS.size() - 1)]
	return "%d x %d" % [size.x, size.y]
