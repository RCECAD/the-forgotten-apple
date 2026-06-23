extends Node2D

signal dialogue_finished

enum CutsceneState {
	IDLE,
	DIALOGUE,
}

const VILLAGER_FRAME_WIDTH := 32
const VILLAGER_FRAME_HEIGHT := 64
const VILLAGER_FRAME_COUNT := 2
const VILLAGER_FRAME_INTERVAL := 0.35
const LEVEL_3_SCENE := "res://scenes/levels/level_3.tscn"

const NO_FLOWER_DIALOGUE := [
	{"speaker": "MORADORA", "text": "Você chegou até aqui sem se desviar tanto.", "view": "normal"},
	{"speaker": "MORADORA", "text": "Talvez ainda consiga seguir com cuidado.", "view": "normal"},
	{
		"speaker": "MORADORA",
		"text": "Leve isto. Pode te ajudar quando a floresta cobrar seu preço.",
		"view": "normal",
	},
]

const WHITE_FLOWER_DIALOGUE := [
	{"speaker": "MORADORA", "text": "Essa flor...", "view": "normal"},
	{"speaker": "MORADORA", "text": "Então ele também te convenceu a sair do caminho?", "view": "normal"},
	{"speaker": "GAROTA", "text": "Sim, peguei enquanto passava por ai..", "view": "normal"},
	{
		"speaker": "MORADORA",
		"text": "Preste atenção: nem todo guia quer te levar ao destino certo.",
		"view": "normal",
	},
]

@onready var _player: CharacterBody2D = $Player
@onready var _player_sprite: AnimatedSprite2D = $Player/AnimatedSprite2D
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _villager: Sprite2D = $Villager
@onready var _villager_interaction: Area2D = $VillagerInteraction
@onready var _interior_hum: AudioStreamPlayer = $InteriorHum

var _state := CutsceneState.IDLE
var _is_transitioning := false
var _villager_animating := false
var _villager_frame := 0
var _villager_frame_elapsed := 0.0

func _ready() -> void:
	_villager.region_enabled = true
	_set_villager_frame(0)
	_interact_prompt.visible = false
	_villager_interaction.monitoring = true
	_face_characters_toward_each_other()
	_interior_hum.play()
	get_node("/root/GameSettings").call("apply_audio")

func _process(delta: float) -> void:
	if _is_transitioning or _is_modal_active():
		_interact_prompt.visible = false
	else:
		_interact_prompt.visible = _villager_interaction.overlaps_body(_player)

	if !_villager_animating:
		return

	_villager_frame_elapsed += delta
	if _villager_frame_elapsed < VILLAGER_FRAME_INTERVAL:
		return

	_villager_frame_elapsed = 0.0
	_villager_frame = (_villager_frame + 1) % VILLAGER_FRAME_COUNT
	_set_villager_frame(_villager_frame)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_modal_active():
		return
	if !event.is_action_pressed("interact"):
		return

	if _villager_interaction.overlaps_body(_player):
		get_viewport().set_input_as_handled()
		_start_npc_dialogue()

func _start_npc_dialogue() -> void:
	if _state != CutsceneState.IDLE:
		return

	_state = CutsceneState.DIALOGUE
	_lock_player()
	_face_characters_toward_each_other()
	_villager_animating = true

	var game_state := get_node("/root/GameState")
	if get_node("/root/InventoryManager").has_item("white_flower"):
		await get_node("/root/DialogManager").start_dialog(WHITE_FLOWER_DIALOGUE, false)
		game_state.set("has_white_flower", false)
		game_state.set("gave_white_flower_to_npc", true)
		game_state.set("white_flower_quest_started", true)
		get_node("/root/InventoryManager").remove_item("white_flower")
	else:
		game_state.set("white_flower_quest_started", true)
		await get_node("/root/DialogManager").start_dialog(NO_FLOWER_DIALOGUE, false)

	await get_node("/root/InventoryManager").collect_apple_with_presentation(false)
	_finish_dialogue_and_go_to_next_level()

func _finish_dialogue_and_go_to_next_level() -> void:
	_is_transitioning = true
	_interact_prompt.visible = false
	_villager_animating = false
	_set_villager_frame(0)
	_state = CutsceneState.IDLE
	dialogue_finished.emit()
	get_node("/root/SceneTransition").transition_to(LEVEL_3_SCENE)

func _lock_player() -> void:
	_player.set_input_enabled(false)
	_player.velocity = Vector2.ZERO
	_player_sprite.play("idle")

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

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
