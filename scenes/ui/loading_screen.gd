extends Control

@export_file("*.tscn") var next_scene_path := "res://scenes/ui/main_menu.tscn"
@export var minimum_duration := 1.1

@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _runner: AnimatedSprite2D = $RunnerAnchor/Runner

var _elapsed := 0.0
var _is_finishing := false

func _ready() -> void:
	_runner.play("run")

func _process(delta: float) -> void:
	if _is_finishing:
		return

	_elapsed += delta
	var progress_value := clampf(_elapsed / minimum_duration, 0.0, 1.0)
	_progress_bar.value = ease(progress_value, -2.0) * 100.0

	if _elapsed >= minimum_duration:
		_finish_loading()

func _finish_loading() -> void:
	if _is_finishing:
		return

	_is_finishing = true
	_progress_bar.value = 100.0
	if !ResourceLoader.exists(next_scene_path):
		push_error("Scene does not exist: %s" % next_scene_path)
		return

	get_node("/root/SceneTransition").transition_to(next_scene_path)
