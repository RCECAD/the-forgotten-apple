extends Node2D

@onready var _player: CharacterBody2D = $Ground/Player
@onready var _camera: Camera2D = $Camera2D
@onready var _background_source: Sprite2D = $Background0
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _interact_prompt: Label = $Ground/Player/InteractPrompt
@onready var _villager_tend_trigger: Area2D = $VillagerTendTrigger
@onready var _white_flower: Area2D = $WhiteFlower
@onready var _wind_sound: AudioStreamPlayer = $WindSound
@onready var _music_sound: AudioStreamPlayer = $MusicSound
@onready var _bees: Array[Node] = [
	$BeeEnemy,
	$BeeEnemy2,
	$BeeEnemy3,
]

const CAMERA_SMOOTH_SPEED := 6.0
const VILLAGER_TEND_LEVEL_SCENE := "res://scenes/levels/villager_tend_level.tscn"
const BG_SKY_TEXTURE := preload("res://assets/textures/backgrounds/background_0.png")
const BG_TREES_TEXTURE := preload("res://assets/textures/backgrounds/background_1_2.png")
const BG_Z_INDEX := -30
const BG_REPEAT_EXTRA_TILES := 4
const BG_SKY_OFFSET := Vector2(-2.0, -20.5)
const BG_FRONT_TREES_OFFSET := Vector2(-2.0, -50.0)
const BG_FILL_COLOR := Color(0.25, 0.38, 0.55)
const BG_FILL_HALF_SIZE := Vector2(20000.0, 20000.0)
const CAVE_EXTERIOR_START_X := 1500.0
const BEE_BUZZ_RADIUS := 420.0
const AUDIO_FADE_DURATION := 0.65
const AUDIO_FADE_MIN_DB := -60.0

var _camera_start_x: float
var _camera_start_y: float
var _camera_start_position: Vector2
var _follow_player := false
var _is_transitioning := false
var _parallax_layers: Array[Dictionary] = []

func _ready() -> void:
	_camera.make_current()
	_camera_start_x = _camera.global_position.x
	_camera_start_y = _camera.global_position.y
	_camera_start_position = _camera.global_position
	_build_parallax_background()
	_interact_prompt.visible = false
	_villager_tend_trigger.monitoring = true
	_apply_spawn_marker()
	_update_bee_buzz_audio()
	_music_sound.play()
	_update_parallax_background()

func _process(delta: float) -> void:
	if _is_transitioning:
		_interact_prompt.visible = false
		return

	if _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = _can_interact_with_white_flower() or _villager_tend_trigger.overlaps_body(_player)
	_update_bee_buzz_audio()
	_update_camera(delta)
	_update_parallax_background()

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_modal_active():
		return

	if event.is_action_pressed("ui_cancel") and !_pause_menu.visible:
		_pause_menu.open_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and _can_interact_with_white_flower():
		get_viewport().set_input_as_handled()
		_white_flower.call("collect")
	elif event.is_action_pressed("interact") and _villager_tend_trigger.overlaps_body(_player):
		_is_transitioning = true
		_interact_prompt.visible = false
		await _fade_out_level_audio()
		get_node("/root/SceneTransition").transition_to(VILLAGER_TEND_LEVEL_SCENE)

func _update_camera(delta: float) -> void:
	if !_follow_player and _player.global_position.x > _camera_start_x:
		_follow_player = true

	var target_x := _camera_start_x
	var target_y := _camera_start_y
	if _follow_player:
		target_x = round(_player.global_position.x)
		target_y = round(_player.global_position.y)

	var smooth_factor := 1.0 - exp(-CAMERA_SMOOTH_SPEED * delta)
	_camera.global_position.x = lerp(_camera.global_position.x, target_x, smooth_factor)
	_camera.global_position.y = lerp(_camera.global_position.y, target_y, smooth_factor)
	_camera.global_position = _camera.global_position.round()

func _build_parallax_background() -> void:
	_background_source.visible = false
	_add_background_fill()
	_add_parallax_layer(BG_SKY_TEXTURE, Vector2(2.23, 2.02), BG_SKY_OFFSET, 0.08, BG_Z_INDEX - 2)
	_add_parallax_layer(BG_TREES_TEXTURE, Vector2(2.23, 2.02), BG_FRONT_TREES_OFFSET, 0.28, BG_Z_INDEX - 1)

func _add_background_fill() -> void:
	var fill := Polygon2D.new()
	fill.name = "GeneratedBackgroundFill"
	fill.color = BG_FILL_COLOR
	fill.z_index = BG_Z_INDEX - 3
	fill.polygon = PackedVector2Array([
		Vector2(-BG_FILL_HALF_SIZE.x, -BG_FILL_HALF_SIZE.y),
		Vector2(BG_FILL_HALF_SIZE.x, -BG_FILL_HALF_SIZE.y),
		Vector2(BG_FILL_HALF_SIZE.x, BG_FILL_HALF_SIZE.y),
		Vector2(-BG_FILL_HALF_SIZE.x, BG_FILL_HALF_SIZE.y),
	])
	add_child(fill)
	move_child(fill, 0)

func _add_parallax_layer(texture: Texture2D, layer_scale: Vector2, initial_offset: Vector2, motion_factor: float, z_index: int) -> void:
	var layer := Node2D.new()
	layer.name = "GeneratedParallaxLayer"
	layer.z_index = z_index
	add_child(layer)
	move_child(layer, 0)

	var spacing := float(texture.get_width()) * layer_scale.x
	var visible_width := get_viewport_rect().size.x / _camera.zoom.x
	var tile_count := int(ceil(visible_width / spacing)) + BG_REPEAT_EXTRA_TILES
	var sprites: Array[Sprite2D] = []
	for index in tile_count:
		var sprite := Sprite2D.new()
		sprite.name = "Tile%d" % index
		sprite.texture = texture
		sprite.scale = layer_scale
		sprite.y_sort_enabled = false
		layer.add_child(sprite)
		sprites.append(sprite)

	_parallax_layers.append({
		"node": layer,
		"sprites": sprites,
		"initial_offset": initial_offset,
		"motion_factor": motion_factor,
		"spacing": spacing,
	})

func _update_parallax_background() -> void:
	var camera_delta := _camera.global_position - _camera_start_position
	for layer_data in _parallax_layers:
		var layer := layer_data["node"] as Node2D
		var sprites := layer_data["sprites"] as Array[Sprite2D]
		var initial_offset := layer_data["initial_offset"] as Vector2
		var motion_factor := float(layer_data["motion_factor"])
		var spacing := float(layer_data["spacing"])

		layer.global_position = (_camera.global_position + initial_offset - camera_delta * motion_factor).round()

		var center_local_x := _camera.global_position.x - layer.global_position.x
		var first_tile := int(floor(center_local_x / spacing)) - int(sprites.size() / 2)
		for index in sprites.size():
			var sprite := sprites[index]
			sprite.position = Vector2((first_tile + index) * spacing, 0.0).round()

func _apply_spawn_marker() -> void:
	var spawn_marker := get_node_or_null("CabinExitSpawn") as Marker2D
	if spawn_marker == null:
		return

	var marker_name: String = get_node("/root/SceneTransition").consume_spawn_marker()
	if marker_name != spawn_marker.name:
		return

	_player.global_position = spawn_marker.global_position
	_follow_player = true
	_camera.global_position.x = round(_player.global_position.x)
	_camera.global_position.y = round(_player.global_position.y)
	_update_parallax_background()

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)

func _can_interact_with_white_flower() -> bool:
	return is_instance_valid(_white_flower) and bool(_white_flower.call("can_interact"))

func _set_bee_buzz_enabled(enabled: bool) -> void:
	for bee in _bees:
		bee.set("buzz_enabled", enabled)

func _update_bee_buzz_audio() -> void:
	var is_exterior := _player.global_position.x >= CAVE_EXTERIOR_START_X
	for bee in _bees:
<<<<<<< HEAD
		var is_near_player: bool = bee.global_position.distance_to(_player.global_position) <= BEE_BUZZ_RADIUS
=======
		var is_near_player: bool = (bee as Node2D).global_position.distance_to(_player.global_position) <= BEE_BUZZ_RADIUS
>>>>>>> f944071 (feat;: add oven)
		bee.set("buzz_enabled", is_exterior and is_near_player)

func _fade_out_level_audio() -> void:
	var audio_players: Array[AudioStreamPlayer] = [_music_sound, _wind_sound]
	var has_playing_audio := false
	var tween := create_tween()
	tween.set_parallel(true)
	for player in audio_players:
		if player.playing:
			has_playing_audio = true
			tween.tween_property(
				player,
				"volume_db",
				AUDIO_FADE_MIN_DB,
				AUDIO_FADE_DURATION
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	for bee in _bees:
		var buzz_audio := bee.get_node_or_null("BeeBuzzAudio") as AudioStreamPlayer2D
		if buzz_audio != null and buzz_audio.playing:
			has_playing_audio = true
			tween.tween_property(
				buzz_audio,
				"volume_db",
				AUDIO_FADE_MIN_DB,
				AUDIO_FADE_DURATION
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	if !has_playing_audio:
		tween.kill()
		_set_bee_buzz_enabled(false)
		return

	await tween.finished
	_set_bee_buzz_enabled(false)
	for player in audio_players:
		player.stop()
