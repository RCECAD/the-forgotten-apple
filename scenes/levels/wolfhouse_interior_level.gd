extends Node2D

const LEVEL_4_SCENE := "res://scenes/levels/level_4.tscn"
const WOLF_FRAME_WIDTH := 32
const WOLF_FRAME_HEIGHT := 32
const GRANDMA_FRAME_WIDTH := 40
const GRANDMA_FRAME_HEIGHT := 64
const CALM_WOLF_SCALE := Vector2(1.75, 1.75)
const THREAT_WOLF_SCALE := Vector2(2.0, 2.0)
const PLAYER_APPROACH_POSITION := Vector2(640, 488)
const WOLF_APPROACH_POSITION := Vector2(712, 468)
const CALM_DIALOGUE := [
	{"speaker": "LOBO", "text": "Sua vovó sempre gostou de maçãs quentes."},
	{"speaker": "GAROTA", "text": "Onde ela está?"},
	{"speaker": "LOBO", "text": "Perto o suficiente para ouvir você."},
	"O forno se abre com um estalo seco.",
	"A garota se aproxima."
]
const THREAT_DIALOGUE := [
	{"speaker": "LOBO", "text": "Histórias antigas precisam terminar do jeito certo."},
	"Ele empurra a garota para dentro do forno e fecha a porta."
]
const DARKEN_ALPHA := 0.5

@onready var _player: CharacterBody2D = $Player
@onready var _player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _wolf: Sprite2D = $Wolf
@onready var _grandma: Sprite2D = $Grandma
@onready var _darken_overlay: ColorRect = $CutsceneLayer/CutsceneDarken

var _is_transitioning := false
var _cutscene_running := false

func _ready() -> void:
	_interact_prompt.visible = false
	_configure_scene_sprites()
	_darken_overlay.color.a = 0.0
	_lock_player()
	call_deferred("_start_cutscene")

func _process(_delta: float) -> void:
	if _is_transitioning or _cutscene_running or _is_modal_active():
		_interact_prompt.visible = false
		return

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _cutscene_running or _is_modal_active():
		return

	if event.is_action_pressed("ui_cancel"):
		if !_pause_menu.visible:
			_pause_menu.open_menu()
			get_viewport().set_input_as_handled()

func _start_cutscene() -> void:
	if _cutscene_running or _is_transitioning:
		return

	_cutscene_running = true
	_face_characters()
	await get_tree().create_timer(0.5).timeout
	await get_node("/root/DialogManager").start_dialog(CALM_DIALOGUE, false)
	_set_wolf_threat_pose()
	await _move_to_oven()
	await get_node("/root/DialogManager").start_dialog(THREAT_DIALOGUE, false)
	await _darken_room()
	_transition_to_oven()

func _configure_scene_sprites() -> void:
	_wolf.region_enabled = true
	_wolf.region_rect = Rect2(0, 0, WOLF_FRAME_WIDTH, WOLF_FRAME_HEIGHT)
	_wolf.scale = CALM_WOLF_SCALE
	_grandma.region_enabled = true
	_grandma.region_rect = Rect2(0, 0, GRANDMA_FRAME_WIDTH, GRANDMA_FRAME_HEIGHT)

func _set_wolf_threat_pose() -> void:
	_wolf.scale = THREAT_WOLF_SCALE
	_wolf.modulate = Color(1.0, 0.83, 0.83)

func _move_to_oven() -> void:
	_player_sprite.play("walk")
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_player, "position", PLAYER_APPROACH_POSITION, 1.0).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_wolf, "position", WOLF_APPROACH_POSITION, 1.0).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	_player_sprite.play("idle")
	_face_characters()

func _darken_room() -> void:
	var tween := create_tween()
	tween.tween_property(_darken_overlay, "color:a", DARKEN_ALPHA, 0.45).set_trans(
		Tween.TRANS_SINE
	).set_ease(Tween.EASE_OUT)
	await tween.finished

func _transition_to_oven() -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	get_node("/root/SceneTransition").transition_to(LEVEL_4_SCENE)

func _lock_player() -> void:
	_player.set_input_enabled(false)
	_player.velocity = Vector2.ZERO
	_player_sprite.play("idle")

func _face_characters() -> void:
	_player_sprite.flip_h = false
	_wolf.flip_h = true
	_grandma.flip_h = false

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
