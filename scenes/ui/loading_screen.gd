extends Control

@export_file("*.tscn") var next_scene_path := "res://scenes/ui/main_menu.tscn"
@export var minimum_duration := 1.4
@export var completion_hold := 0.25

@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _progress_label: Label = %ProgressLabel
@onready var _apple_marker: TextureRect = %AppleMarker
@onready var _wind_sound: AudioStreamPlayer = %WindSound

var _elapsed := 0.0
var _displayed_progress := 0.0
var _target_progress := 0.0
var _loaded_scene: PackedScene
var _is_finishing := false
var _load_started := false
var _wind_target_db := 0.0

func _ready() -> void:
	_progress_bar.value = 0.0
	_update_progress_visuals()
	await get_tree().process_frame
	_start_ambient_audio()
	_start_threaded_load()

func _process(delta: float) -> void:
	if _is_finishing:
		return

	_elapsed += delta
	_poll_threaded_load()
	_displayed_progress = move_toward(
		_displayed_progress,
		_target_progress,
		delta * 48.0
	)
	_progress_bar.value = clampf(_displayed_progress, 0.0, 100.0)
	_update_progress_visuals()

	if (
		_loaded_scene != null
		and _elapsed >= minimum_duration
		and _displayed_progress >= 99.5
	):
		_finish_loading()

func _start_threaded_load() -> void:
	if _load_started:
		return
	_load_started = true
	if !ResourceLoader.exists(next_scene_path):
		_fail_loading("Scene does not exist: %s" % next_scene_path)
		return
	var error := ResourceLoader.load_threaded_request(next_scene_path, "PackedScene", true)
	if error != OK:
		_fail_loading("Could not start threaded loading for: %s" % next_scene_path)

func _poll_threaded_load() -> void:
	if !_load_started or _loaded_scene != null:
		return

	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if !progress.is_empty():
				_target_progress = clampf(float(progress[0]) * 100.0, 0.0, 95.0)
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource := ResourceLoader.load_threaded_get(next_scene_path)
			if resource is PackedScene:
				_loaded_scene = resource as PackedScene
				_target_progress = 100.0
			else:
				_fail_loading("Loaded resource is not a PackedScene: %s" % next_scene_path)
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail_loading("Threaded loading failed for: %s" % next_scene_path)

func _finish_loading() -> void:
	if _is_finishing:
		return
	_is_finishing = true
	_progress_bar.value = 100.0
	_displayed_progress = 100.0
	_update_progress_visuals()
	await get_tree().create_timer(completion_hold).timeout
	var audio_tween := create_tween()
	audio_tween.tween_property(_wind_sound, "volume_db", -60.0, 0.35)
	await audio_tween.finished
	get_node("/root/SceneTransition").transition_to_packed(_loaded_scene)

func _fail_loading(message: String) -> void:
	push_error(message)
	_load_started = false
	_is_finishing = true
	_progress_label.text = "Não foi possível carregar o menu."

func _update_progress_visuals() -> void:
	var percent := clampi(int(round(_progress_bar.value)), 0, 100)
	_progress_label.text = "Carregando... %d%%" % percent
	var bar_rect := _progress_bar.get_global_rect()
	var ratio := float(percent) / 100.0
	_apple_marker.global_position = Vector2(
		bar_rect.position.x + bar_rect.size.x * ratio - _apple_marker.size.x * 0.5,
		bar_rect.position.y + (bar_rect.size.y - _apple_marker.size.y) * 0.5
	)

func _start_ambient_audio() -> void:
	_wind_target_db = _wind_sound.volume_db
	_wind_sound.volume_db = -60.0
	_wind_sound.play()
	var tween := create_tween()
	tween.tween_property(_wind_sound, "volume_db", _wind_target_db, 0.65)
