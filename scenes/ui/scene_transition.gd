extends CanvasLayer

const FADE_DURATION := 0.35
const AUDIO_FADE_MIN_DB := -60.0

var _is_transitioning := false
var _fade_rect: ColorRect
var _master_bus_index := 0
var _master_volume_db := 0.0
var _spawn_marker := ""

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_master_bus_index = AudioServer.get_bus_index("Master")
	_master_volume_db = AudioServer.get_bus_volume_db(_master_bus_index)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate = Color(1, 1, 1, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)

func transition_to(scene_path: String, spawn_marker := "") -> void:
	if _is_transitioning:
		return
	if !ResourceLoader.exists(scene_path):
		push_error("Scene does not exist: %s" % scene_path)
		return

	_is_transitioning = true
	_spawn_marker = spawn_marker
	get_tree().paused = false
	await _fade_to(1.0)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _fade_to(0.0)
	_is_transitioning = false

func consume_spawn_marker() -> String:
	var marker := _spawn_marker
	_spawn_marker = ""
	return marker

func reload_current_scene() -> void:
	if _is_transitioning:
		return

	var current_scene := get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path == "":
		push_error("Current scene cannot be reloaded.")
		return

	_is_transitioning = true
	_spawn_marker = ""
	get_tree().paused = false
	await _fade_out_with_audio()
	get_tree().change_scene_to_file(current_scene.scene_file_path)
	await get_tree().process_frame
	await _fade_in_with_audio()
	_is_transitioning = false

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished

func _fade_out_with_audio() -> void:
	_master_volume_db = AudioServer.get_bus_volume_db(_master_bus_index)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_method(_set_master_volume_db, _master_volume_db, AUDIO_FADE_MIN_DB, FADE_DURATION)
	await tween.finished

func _fade_in_with_audio() -> void:
	AudioServer.set_bus_volume_db(_master_bus_index, AUDIO_FADE_MIN_DB)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_method(_set_master_volume_db, AUDIO_FADE_MIN_DB, _master_volume_db, FADE_DURATION)
	await tween.finished

func _set_master_volume_db(volume_db: float) -> void:
	AudioServer.set_bus_volume_db(_master_bus_index, volume_db)
