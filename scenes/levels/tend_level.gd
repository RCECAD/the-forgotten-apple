extends Node2D

signal dialogue_finished

enum CutsceneState {
	IDLE,
	STARTING,
	DIALOGUE,
	FINISHING,
	FINISHED,
}

const WOLF_FRAME_WIDTH := 32
const WOLF_FRAME_HEIGHT := 32
const WOLF_FRAME_COUNT := 50
const WOLF_FRAME_INTERVAL := 0.06
const FOREST_FADE_DURATION := 0.55

const DIALOGUE := [
	{"speaker": "GAROTA", "text": "Um lobo...", "view": "normal"},
	{"speaker": "LOBO", "text": "Uma garota...", "view": "normal"},
	{"speaker": "GAROTA", "text": "Você estava me seguindo?", "view": "normal"},
	{"speaker": "LOBO", "text": "Não. Você é que chegou até onde eu estava.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Então saia do caminho.", "view": "normal"},
	{"speaker": "LOBO", "text": "Você pretende entrar na floresta?", "view": "normal"},
	{"speaker": "GAROTA", "text": "Pretendo.", "view": "normal"},
	{"speaker": "LOBO", "text": "Sozinha?", "view": "normal"},
	{"speaker": "GAROTA", "text": "Não preciso da sua ajuda.", "view": "normal"},
	{"speaker": "LOBO", "text": "Ainda não.", "view": "normal"},
	{"speaker": "GAROTA", "text": "O que isso quer dizer?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Pessoas corajosas costumam entrar nessa floresta. Poucas continuam corajosas depois.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Estou procurando minha avó.", "view": "normal"},
	{"speaker": "LOBO", "text": "Não conheço sua avó.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Então não pode me ajudar.", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Talvez eu não conheça quem você procura. Mas conheço o lugar onde pretende procurar.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "O que há nessa floresta?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Mais coisas do que você conseguiria ver.",
		"view": "normal",
	},
	{
		"speaker": "LOBO",
		"text": "Durante o dia, a floresta parece apenas silenciosa.",
		"view": "forest",
	},
	{
		"speaker": "LOBO",
		"text": "Mas, quanto mais fundo você entrar, menos poderá confiar nos próprios olhos.",
		"view": "forest",
	},
	{
		"speaker": "LOBO",
		"text": "Algumas plantas se fecham quando sentem passos. Outras escondem espinhos sob as folhas.",
		"view": "forest",
	},
	{
		"speaker": "LOBO",
		"text": "As raízes atravessam o chão como armadilhas, e existem lugares onde a névoa esconde até mesmo a direção de onde você veio.",
		"view": "forest",
	},
	{
		"speaker": "LOBO",
		"text": "Você também encontrará criaturas que protegem seus territórios.",
		"view": "forest",
	},
	{
		"speaker": "LOBO",
		"text": "Algumas atacarão imediatamente. Outras esperarão você baixar a guarda.",
		"view": "forest",
	},
	{"speaker": "GAROTA", "text": "E como eu atravesso tudo isso?", "view": "forest"},
	{"speaker": "LOBO", "text": "Observe antes de avançar.", "view": "forest"},
	{
		"speaker": "LOBO",
		"text": "Nem sempre o caminho mais fácil é seguro. Nem sempre aquilo que parece perigoso pretende ferir você.",
		"view": "forest",
	},
	{"speaker": "GAROTA", "text": "Isso inclui você?", "view": "forest"},
	{"speaker": "LOBO", "text": "Principalmente eu.", "view": "forest"},
	{"speaker": "GAROTA", "text": "Por que está me avisando?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Porque você entraria mesmo que eu não dissesse nada.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Talvez eu saiba me proteger.", "view": "normal"},
	{"speaker": "LOBO", "text": "Talvez.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Você duvida de mim?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Eu duvido de todos que entram nessa floresta com tanta certeza.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Eu preciso encontrar minha avó.", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Então não deixe a pressa escolher por você.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Sabe onde devo começar?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Continue seguindo em frente. Por enquanto, a floresta ainda permite isso.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Por enquanto?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Mais adiante, ela começará a exigir escolhas.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "E quando isso acontecer?", "view": "normal"},
	{
		"speaker": "LOBO",
		"text": "Você terá que decidir em quem confiar.",
		"view": "normal",
	},
	{"speaker": "GAROTA", "text": "Não pretendo confiar em você.", "view": "normal"},
	{"speaker": "LOBO", "text": "Isso pode mantê-la viva.", "view": "normal"},
	{
		"speaker": "GAROTA",
		"text": "Ou pode ser exatamente o que você quer que eu pense.",
		"view": "normal",
	},
	{"speaker": "LOBO", "text": "Você aprende rápido.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Espere. Qual é o seu nome?", "view": "normal"},
	{"speaker": "LOBO", "text": "Você ainda não precisa saber.", "view": "normal"},
	{"speaker": "GAROTA", "text": "Vou encontrar você novamente?", "view": "normal"},
	{"speaker": "LOBO", "text": "Se conseguir atravessar a floresta.", "view": "normal"},
]

@export var forest_illustration: Texture2D

@onready var _player: CharacterBody2D = $Player
@onready var _player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var _wolf: Sprite2D = $Wolf
@onready var _interior: Sprite2D = $InteriorTend
@onready var _forest_image: TextureRect = %ForestImage
@onready var _interior_hum: AudioStreamPlayer = $InteriorHum

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

	_state = CutsceneState.FINISHING
	await _set_forest_view(false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_wolf, "position:x", _wolf.position.x + 150.0, 0.85).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	tween.tween_property(_wolf, "modulate:a", 0.0, 0.85)
	await tween.finished
	_wolf.visible = false
	_unlock_player()
	_state = CutsceneState.FINISHED
	dialogue_finished.emit()

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
