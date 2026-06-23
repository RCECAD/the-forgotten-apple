extends Node2D

signal dialogue_finished

enum CutsceneState {
	IDLE,
	STARTING,
	DIALOGUE,
	FINISHED,
}

const WOLF_FRAME_WIDTH := 32
const WOLF_FRAME_HEIGHT := 32
const WOLF_FRAME_COUNT := 50
const WOLF_FRAME_INTERVAL := 0.06
const EMPTY_LEVEL_SCENE := "res://scenes/levels/empty_level.tscn"

const DIALOGUE := [
	{"speaker": "GAROTA", "text": "Então era aqui que você estava.", "view": "normal"},
	{"speaker": "LOBO", "text": "Eu disse que talvez nos encontrássemos de novo.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Eu atravessei a floresta. Agora me diga onde está minha avó.", "view": "normal"},
	{"speaker": "LOBO", "text": "Sua avó não se perdeu por acaso.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Você sabe o que aconteceu com ela?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Se eu desse uma resposta fácil, você correria até ela sem olhar para o chão.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Eu cansei dos seus avisos.", "view": "normal"},
	{"speaker": "LOBO", "text": "E ainda assim eles trouxeram você até aqui viva.", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Há uma casa adiante. Um forno apagado. Uma maçã esquecida. E uma escolha que não parece escolha.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Isso deveria me ajudar?", "view": "normal"},
	{"speaker": "LOBO", "text": "Deveria fazer você parar antes de entrar.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Eu não vou voltar.", "view": "normal"},
	{"speaker": "LOBO", "text": "Eu sei.", "view": "normal"},
	{"speaker": "LOBO", "text": "Então vá devagar.", "view": "normal"},
]

@onready var _player: CharacterBody2D = $Player
@onready var _player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var _wolf: Sprite2D = $Wolf
@onready var _interact_prompt: Label = $Player/InteractPrompt

var _state := CutsceneState.IDLE
var _wolf_wagging := false
var _wolf_frame := 0
var _wolf_frame_elapsed := 0.0

func _ready() -> void:
	_interact_prompt.visible = false
	_wolf.region_enabled = true
	_set_wolf_frame(0)
	_face_characters_toward_each_other()
	_lock_player()
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
	if _state != CutsceneState.IDLE:
		return

	_state = CutsceneState.STARTING
	_lock_player()
	_face_characters_toward_each_other()
	_wolf_wagging = true
	await get_tree().create_timer(0.65).timeout
	_wolf_wagging = false
	_set_wolf_frame(0)

	_state = CutsceneState.DIALOGUE
	await get_node("/root/DialogManager").start_dialog(DIALOGUE, false)
	await _finish_cutscene()

func _finish_cutscene() -> void:
	if _state != CutsceneState.DIALOGUE:
		return

	_state = CutsceneState.FINISHED
	dialogue_finished.emit()
	get_node("/root/SceneTransition").transition_to(EMPTY_LEVEL_SCENE)

func _lock_player() -> void:
	_player.set_input_enabled(false)
	_player.velocity = Vector2.ZERO
	_player_sprite.play("idle")

func _face_characters_toward_each_other() -> void:
	_player_sprite.flip_h = _wolf.global_position.x < _player.global_position.x
	_wolf.flip_h = _player.global_position.x < _wolf.global_position.x

func _set_wolf_frame(frame: int) -> void:
	_wolf.region_rect = Rect2(
		frame * WOLF_FRAME_WIDTH,
		0,
		WOLF_FRAME_WIDTH,
		WOLF_FRAME_HEIGHT
	)
