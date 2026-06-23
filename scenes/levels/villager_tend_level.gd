extends Node2D

signal dialogue_finished

enum CutsceneState {
	IDLE,
	STARTING,
	DIALOGUE,
	FINISHED,
}

const VILLAGER_FRAME_WIDTH := 32
const VILLAGER_FRAME_HEIGHT := 64
const VILLAGER_FRAME_COUNT := 2
const VILLAGER_FRAME_INTERVAL := 0.35
const LEVEL_3_SCENE := "res://scenes/levels/level_3.tscn"

const DIALOGUE := [
	{"speaker": "GAROTA", "text": "Desculpe... havia um lobo por aqui?", "view": "normal"},
	{"speaker": "MORADORA", "text": "Um lobo? Ouvi dizer que ele passou pela trilha cedo.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Ele ainda está perto?", "view": "normal"},
	{"speaker": "MORADORA", "text": "Acho que não. Pelo que contaram, ele seguiu viagem floresta adentro.", "view": "normal"},
	{"speaker": "MORADORA", "text": "Você parece cansada. Eu deixo você descansar aqui antes de continuar.", "view": "normal"},
]

@onready var _player: CharacterBody2D = $Player
@onready var _player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var _villager: Sprite2D = $Villager
@onready var _interior_hum: AudioStreamPlayer = $InteriorHum

var _state := CutsceneState.IDLE
var _villager_animating := false
var _villager_frame := 0
var _villager_frame_elapsed := 0.0

func _ready() -> void:
	_villager.region_enabled = true
	_set_villager_frame(0)
	_face_characters_toward_each_other()
	_lock_player()
	_interior_hum.play()
	get_node("/root/GameSettings").call("apply_audio")
	call_deferred("_start_cutscene")

func _process(delta: float) -> void:
	if !_villager_animating:
		return

	_villager_frame_elapsed += delta
	if _villager_frame_elapsed < VILLAGER_FRAME_INTERVAL:
		return

	_villager_frame_elapsed = 0.0
	_villager_frame = (_villager_frame + 1) % VILLAGER_FRAME_COUNT
	_set_villager_frame(_villager_frame)

func _start_cutscene() -> void:
	if _state != CutsceneState.IDLE:
		return

	_state = CutsceneState.STARTING
	_lock_player()
	_face_characters_toward_each_other()
	_villager_animating = true
	await get_tree().create_timer(0.65).timeout

	_state = CutsceneState.DIALOGUE
	await get_node("/root/DialogManager").start_dialog(DIALOGUE, false)
	await _finish_cutscene()

func _finish_cutscene() -> void:
	if _state != CutsceneState.DIALOGUE:
		return

	_state = CutsceneState.FINISHED
	_villager_animating = false
	_set_villager_frame(0)
	_unlock_player()
	dialogue_finished.emit()
	get_node("/root/SceneTransition").transition_to(LEVEL_3_SCENE)

func _lock_player() -> void:
	_player.set_input_enabled(false)
	_player.velocity = Vector2.ZERO
	_player_sprite.play("idle")

func _unlock_player() -> void:
	_player.set_input_enabled(true)

func _face_characters_toward_each_other() -> void:
	_player_sprite.flip_h = _villager.global_position.x < _player.global_position.x
	_villager.flip_h = _player.global_position.x < _villager.global_position.x

func _set_villager_frame(frame: int) -> void:
	_villager.region_rect = Rect2(
		frame * VILLAGER_FRAME_WIDTH,
		0,
		VILLAGER_FRAME_WIDTH,
		VILLAGER_FRAME_HEIGHT
	)
