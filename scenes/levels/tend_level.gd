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
const FOREST_FADE_DURATION := 0.55

const DIALOGUE := [
	{"speaker": "GAROTA", "text": "...", "view": "normal"},
	{"speaker": "GAROTA", "text": "Olá?", "view": "normal"},
	{"speaker": "LOBO", "text": "Que surpresa.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Você mora aqui?", "view": "normal"},
	{"speaker": "LOBO", "text": "Não. Só parei para separar uns suprimentos.", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Nunca se sabe o que pode encontrar pela frente..",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Você se refere à floresta?", "view": "normal"},
	{"speaker": "LOBO", "text": "Com quem entra nela sem olhar para trás, sim.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Entendi.. Estou procurando minha avó..", "view": "normal"},
	{"speaker": "LOBO", "text": "Não conheço sua avó.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Então você não pode me ajudar.", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Não sei quem ela é. Mas sei onde você está pisando.",
		"view": "normal",
	},
	{"speaker": "LOBO", "text": "Esta floresta muda quando você entra fundo demais.", "view": "forest"},
	{
		"speaker": "LOBO",
		"text": "As raízes parecem chão firme, mas prendem seus pés quando você corre.",
		"view": "forest",
	},
	{
		"speaker": "LOBO",
		"text": "A névoa cobre as trilhas, os sons vêm de lugares errados, e algumas criaturas atacam antes que você consiga vê-las.",
		"view": "forest",
	},
	{"speaker": "GAROTA", "text": "Como eu atravesso isso?", "view": "forest"},
	{"speaker": "LOBO", "text": "Devagar. Observando antes de avançar.", "view": "forest"},
	{
		"speaker": "LOBO",
		"text": "O caminho mais fácil costuma ser o primeiro a desaparecer.",
		"view": "forest",
	},
	{"speaker": "GAROTA", "text": "E por que está me dizendo isso?", "view": "forest"},
	{
		"speaker": "LOBO",
		"text": "Porque você parece o tipo de pessoa que seguiria mesmo sem aviso.",
		"view": "forest",
	},
	{"speaker": "GAROTA", "text": "Você fala como se já tivesse se perdido aqui.", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Todos que continuam vivos já se perderam alguma vez.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Eu não tenho escolha. Preciso encontrar minha avó.", "view": "normal"},
	{"speaker": "LOBO", "text": "Então não deixe a pressa escolher por você.", "view": "normal"},
	{"speaker": "GAROTA", "text": "...", "view": "normal"},
	{"speaker": "GAROTA", "text": "Vou encontrar você de novo?", "view": "normal"},
	{"speaker": "LOBO", "text": "Se chegar longe o bastante.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Qual é o seu nome?", "view": "normal"},
	{"speaker": "LOBO", "text": "Ainda não precisa saber.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Que lugar estranho...", "view": "normal"},
]

@export var forest_illustration: Texture2D

@onready var _player: CharacterBody2D = $Player
@onready var _player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var _wolf: Sprite2D = $Wolf
@onready var _interior: Sprite2D = $InteriorTend
@onready var _forest_image: TextureRect = %ForestImage
@onready var _interior_hum: AudioStreamPlayer = $InteriorHum
@onready var _wind_sound: AudioStreamPlayer = $WindSound

var _state := CutsceneState.IDLE
var _current_view := "normal"
var _wolf_wagging := false
var _wolf_frame := 0
var _wolf_frame_elapsed := 0.0
var _forest_tween: Tween

func _ready() -> void:
	_wolf.region_enabled = true
	_set_wolf_frame(0)
	_prepare_forest_illustration()
	_face_characters_toward_each_other()
	_lock_player()
	_wind_sound.play()
	_interior_hum.play()
	get_node("/root/GameSettings").call("apply_audio")
	get_node("/root/DialogManager").dialog_line_started.connect(_on_dialog_line_started)
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
	_unlock_player()
	dialogue_finished.emit()
	get_node("/root/SceneTransition").transition_to(
		"res://scenes/levels/level_2.tscn",
		"EntrySpawn"
	)

func _on_dialog_line_started(entry: Dictionary, _index: int) -> void:
	if _state != CutsceneState.DIALOGUE:
		return
	var next_view := str(entry.get("view", "normal"))
	if next_view == _current_view:
		return
	_current_view = next_view
	_set_forest_view(next_view == "forest")

func _set_forest_view(enabled: bool) -> void:
	var target_alpha := 1.0 if enabled else 0.0
	if (
		(_forest_tween == null or !_forest_tween.is_running())
		and is_equal_approx(_forest_image.modulate.a, target_alpha)
	):
		return
	if _forest_tween != null and _forest_tween.is_valid():
		_forest_tween.kill()
	_forest_tween = create_tween()
	_forest_tween.tween_property(
		_forest_image,
		"modulate:a",
		target_alpha,
		FOREST_FADE_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await _forest_tween.finished

func _prepare_forest_illustration() -> void:
	if forest_illustration != null:
		_forest_image.texture = forest_illustration
	else:
		push_warning(
			"Forest illustration is not configured. Using the current level background as fallback."
		)
		_forest_image.texture = _interior.texture
	_forest_image.modulate.a = 0.0

func _lock_player() -> void:
	_player.set_input_enabled(false)
	_player.velocity = Vector2.ZERO
	_player_sprite.play("idle")

func _unlock_player() -> void:
	_player.set_input_enabled(true)

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
