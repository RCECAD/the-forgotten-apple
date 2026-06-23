extends Control

@export_file("*.tscn") var loading_scene_path := "res://scenes/ui/loading_screen.tscn"
@export var minimum_input_delay := 1.5
@export var auto_advance_delay := 5.5
@export var logo_fade_duration := 1.25

@onready var _content: Control = %Content
@onready var _logo: TextureRect = %Logo
@onready var _prompt: Label = %Prompt
@onready var _atmosphere: Control = %Atmosphere

var _elapsed := 0.0
var _is_transitioning := false
var _logo_target_position := Vector2.ZERO
var _particles: Array[Dictionary] = []

func _ready() -> void:
	_create_dust_particles()
	_logo_target_position = _logo.position
	_logo.position.y += 12.0
	_logo.scale = Vector2(0.94, 0.94)
	_logo.pivot_offset = _logo.size * 0.5
	_logo.modulate.a = 0.0
	_prompt.modulate.a = 0.0
	await get_tree().create_timer(0.18).timeout
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_logo, "modulate:a", 1.0, logo_fade_duration)
	tween.tween_property(_logo, "scale", Vector2.ONE, logo_fade_duration).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(_logo, "position", _logo_target_position, logo_fade_duration).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	await tween.finished
	if !_is_transitioning:
		_prompt.modulate.a = 0.72

func _process(delta: float) -> void:
	_elapsed += delta
	_update_dust_particles(delta)
	if _prompt.modulate.a > 0.0:
		_prompt.modulate.a = 0.48 + sin(_elapsed * 2.2) * 0.22
	if _elapsed >= auto_advance_delay:
		_go_to_loading()

func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_pressed()
		and !event.is_echo()
		and _elapsed >= minimum_input_delay
	):
		_go_to_loading()
		get_viewport().set_input_as_handled()

func _go_to_loading() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	set_process_unhandled_input(false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_content, "modulate:a", 0.0, 0.7)
	tween.tween_property(_logo, "scale", Vector2(1.025, 1.025), 0.7)
	await tween.finished
	get_node("/root/SceneTransition").transition_to(loading_scene_path)

func _create_dust_particles() -> void:
	var viewport_size := get_viewport_rect().size
	for index in range(26):
		var particle := ColorRect.new()
		var particle_size := 1.0 + float(index % 3)
		particle.size = Vector2.ONE * particle_size
		particle.position = Vector2(
			randf_range(0.08, 0.92) * viewport_size.x,
			randf_range(0.12, 0.9) * viewport_size.y
		)
		particle.color = Color(1.0, 0.72, 0.3, randf_range(0.12, 0.34))
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_atmosphere.add_child(particle)
		_particles.append({
			"node": particle,
			"speed": randf_range(5.0, 13.0),
			"phase": randf_range(0.0, TAU),
		})

func _update_dust_particles(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	for particle_data in _particles:
		var particle := particle_data["node"] as ColorRect
		var speed := float(particle_data["speed"])
		var phase := float(particle_data["phase"])
		particle.position.y -= speed * delta
		particle.position.x += sin(_elapsed * 0.7 + phase) * delta * 2.0
		if particle.position.y < -4.0:
			particle.position.y = viewport_size.y + randf_range(0.0, 30.0)
			particle.position.x = randf_range(0.08, 0.92) * viewport_size.x
