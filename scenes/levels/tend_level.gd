extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _wolf: Sprite2D = $Wolf
@onready var _credits_dim: ColorRect = $Credits/Dim
@onready var _credits_roll: Control = $Credits/CreditsRoll
@onready var _interior_hum: AudioStreamPlayer = $InteriorHum

const WOLF_FRAME_WIDTH := 32
const WOLF_FRAME_HEIGHT := 32
const WOLF_FRAME_COUNT := 50
const WOLF_FRAME_INTERVAL := 0.06
const WOLF_WAIT_DURATION := 3.0
const CREDITS_SCROLL_DURATION := 10.0

var _wolf_wagging := false
var _wolf_frame := 0
var _wolf_frame_elapsed := 0.0

func _ready() -> void:
	_wolf.region_enabled = true
	_set_wolf_frame(0)
	_credits_dim.visible = false
	_credits_roll.visible = false
	_freeze_player()
	_interior_hum.play()
	get_node("/root/GameSettings").call("apply_audio")
	call_deferred("_start_cutscene")

func _process(delta: float) -> void:
	if !_wolf_wagging:
		return

	_wolf_frame_elapsed += delta
	if _wolf_frame_elapsed < WOLF_FRAME_INTERVAL:
		return

	_wolf_frame_elapsed = 0.0
	_wolf_frame = (_wolf_frame + 1) % WOLF_FRAME_COUNT
	_set_wolf_frame(_wolf_frame)

func _start_cutscene() -> void:
	_wolf_wagging = true
	await get_tree().create_timer(WOLF_WAIT_DURATION).timeout
	_wolf_wagging = false
	_set_wolf_frame(0)
	_wolf.flip_h = true
	await get_tree().create_timer(0.45).timeout
	_show_credits()

func _freeze_player() -> void:
	if _player.has_method("set_input_enabled"):
		_player.set_input_enabled(false)
	_player.velocity = Vector2.ZERO

	var player_sprite := _player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if player_sprite == null:
		return

	player_sprite.flip_h = false
	player_sprite.play("idle")

func _show_credits() -> void:
	_credits_dim.visible = true
	_credits_roll.visible = true
	_credits_dim.modulate.a = 0.0
	_credits_roll.modulate.a = 0.0
	_credits_roll.position = Vector2(0.0, 720.0)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(_credits_dim, "modulate:a", 1.0, 0.8)
	tween.tween_property(_credits_roll, "modulate:a", 1.0, 0.8)
	tween.tween_property(_credits_roll, "position:y", -620.0, CREDITS_SCROLL_DURATION)

func _set_wolf_frame(frame: int) -> void:
	_wolf.region_rect = Rect2(frame * WOLF_FRAME_WIDTH, 0, WOLF_FRAME_WIDTH, WOLF_FRAME_HEIGHT)
