extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _recipe_interactable: Area2D = $AncientRecipeInteractable
@onready var _letters_interactable: Area2D = $GrandmaLettersInteractable
@onready var _flowers_interactable: Area2D = $DriedWhiteFlowersInteractable
@onready var _grandma_shadow: Node2D = $GrandmaShadow
@onready var _camera: Camera2D = $Camera2D

const FURNACE_SCENE := "res://scenes/levels/final_scene.tscn"

var _is_transitioning := false
var _is_reading := false

func _ready() -> void:
	_camera.make_current()
	_interact_prompt.visible = false
	_grandma_shadow.visible = false
	if !bool(get_node("/root/GameState").get("furnace_puzzle_solved")):
		call_deferred("_block_direct_access")
		return

	call_deferred("_start_arrival_sequence")

func _process(_delta: float) -> void:
	if _is_transitioning or _is_reading or _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = _get_available_interactable() != null

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _is_reading:
		return

	if event.is_action_pressed("ui_cancel"):
		if !_pause_menu.visible:
			_pause_menu.open_menu()
			get_viewport().set_input_as_handled()
	elif _pause_menu.visible or _is_modal_active():
		return
	elif event.is_action_pressed("interact"):
		var interactable := _get_available_interactable()
		if interactable == null:
			return
		get_viewport().set_input_as_handled()
		_read_interactable(interactable)

func _block_direct_access() -> void:
	_is_transitioning = true
	get_node("/root/SceneTransition").transition_to(FURNACE_SCENE)

func _start_arrival_sequence() -> void:
	_is_reading = true
	_player.set_input_enabled(false)
	await get_tree().create_timer(0.8).timeout
	await get_node("/root/DialogManager").start_dialog([
		"A garota cai em uma sala escondida sob a casa."
	])
	_is_reading = false

func _get_available_interactable() -> Area2D:
	for interactable in [
		_recipe_interactable,
		_letters_interactable,
		_flowers_interactable,
	]:
		if interactable.overlaps_body(_player):
			return interactable

	return null

func _read_interactable(interactable: Area2D) -> void:
	_is_reading = true
	_interact_prompt.visible = false

	if interactable == _recipe_interactable:
		await _read_recipe()
	elif interactable == _letters_interactable:
		await _read_letters()
	elif interactable == _flowers_interactable:
		await _read_flowers()

	_is_reading = false
	await _check_room_progression()

func _read_recipe() -> void:
	get_node("/root/GameState").set("has_read_recipe", true)
	await get_node("/root/DialogManager").start_dialog([
		"\"Torta do Caminho de Volta\"",
		"Ingredientes:\n\n1 carta escrita com saudade\n1 flor colhida fora do caminho\n1 maçã esquecida\n1 menina que confiou no guia\nfogo baixo até a história recomeçar",
		{"speaker": "GAROTA", "text": "Tudo que eu fiz... era parte da receita."}
	])

func _read_letters() -> void:
	get_node("/root/GameState").set("has_read_letters", true)
	await get_node("/root/DialogManager").start_dialog([
		"\"Você disse que a floresta esqueceria meu nome se eu ficasse com você.\nMas eu ainda lembro da menina que fui.\"",
		"\"Ela virá quando receber minha carta.\nNão a assuste antes da hora.\"",
		{"speaker": "GAROTA", "text": "Ela sabia que eu viria."}
	])

func _read_flowers() -> void:
	get_node("/root/GameState").set("has_seen_flowers", true)
	await get_node("/root/DialogManager").start_dialog([
		"Várias flores brancas estão penduradas na parede.\nNão parecem recentes.",
		{"speaker": "GAROTA", "text": "Eu não fui a primeira."}
	])

func _check_room_progression() -> void:
	var game_state := get_node("/root/GameState")
	var has_read_everything := (
		bool(game_state.get("has_read_recipe"))
		and bool(game_state.get("has_read_letters"))
		and bool(game_state.get("has_seen_flowers"))
	)
	if !has_read_everything or bool(game_state.get("hidden_room_grandma_scene_triggered")):
		return

	game_state.set("hidden_room_grandma_scene_triggered", true)
	await _trigger_grandma_scene()

func _trigger_grandma_scene() -> void:
	_is_reading = true
	_interact_prompt.visible = false
	await get_tree().create_timer(0.35).timeout
	_grandma_shadow.visible = true
	await get_node("/root/DialogManager").start_dialog([
		"A sala fica fria.",
		{"speaker": "VOVÓ", "text": "Você encontrou a receita antes da hora."}
	])
	_is_reading = false

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
