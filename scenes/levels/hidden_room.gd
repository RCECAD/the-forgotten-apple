extends Node2D

@onready var _player: CharacterBody2D = $Player
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _recipe_interactable: Area2D = $AncientRecipeInteractable
@onready var _letters_interactable: Area2D = $GrandmaLettersInteractable
@onready var _flowers_interactable: Area2D = $DriedWhiteFlowersInteractable
@onready var _grandma_shadow: Node2D = $GrandmaShadow
@onready var _wolf_shadow: Node2D = $WolfShadow
@onready var _camera: Camera2D = $Camera2D
@onready var _choice_layer: CanvasLayer = $ChoiceLayer
@onready var _choice_description_label: Label = $ChoiceLayer/ChoicePanel/MarginContainer/ChoiceContent/DescriptionLabel
@onready var _choice_labels: Array[Label] = [
	$ChoiceLayer/ChoicePanel/MarginContainer/ChoiceContent/Options/ConcludeRecipeLabel,
	$ChoiceLayer/ChoicePanel/MarginContainer/ChoiceContent/Options/HelpGrandmaLabel,
	$ChoiceLayer/ChoicePanel/MarginContainer/ChoiceContent/Options/BreakRecipeLabel,
]
@onready var _ending_layer: CanvasLayer = $EndingLayer
@onready var _ending_fade: ColorRect = $EndingLayer/Fade
@onready var _ending_content: Control = $EndingLayer/Content
@onready var _ending_image: TextureRect = $EndingLayer/Content/EndingImage
@onready var _ending_title_label: Label = $EndingLayer/Content/EndingPanel/MarginContainer/EndingContent/TitleLabel
@onready var _ending_text_label: Label = $EndingLayer/Content/EndingPanel/MarginContainer/EndingContent/TextLabel
@onready var _ending_last_line_label: Label = $EndingLayer/Content/EndingPanel/MarginContainer/EndingContent/LastLineLabel
@onready var _ending_action_labels: Array[Label] = [
	$EndingLayer/Content/EndingPanel/MarginContainer/EndingContent/Actions/MenuLabel,
	$EndingLayer/Content/EndingPanel/MarginContainer/EndingContent/Actions/RestartLabel,
]

const FURNACE_SCENE := "res://scenes/levels/level_4.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const NEW_GAME_SCENE := "res://scenes/levels/bedroom_level.tscn"
const SELECTED_COLOR := Color(1.0, 0.84, 0.38)
const UNSELECTED_COLOR := Color(0.82, 0.74, 0.62)
const ACTION_SELECTED_COLOR := Color(1.0, 0.9, 0.55)
const ACTION_UNSELECTED_COLOR := Color(0.72, 0.66, 0.58)
const FINAL_CHOICES := [
	{
		"label": "Concluir a receita",
		"description": "Colocar a maçã no forno e terminar o ritual.",
		"ending": "bad_ending_next_girl",
		"title": "Final ruim - A próxima menina",
		"image": "res://assets/ui/bad_ending_next_girl.jpeg",
		"lines": [
			"A garota coloca a maçã no forno.",
			"O forno acende sozinho.",
			"O lobo sorri.",
			"A vovó fecha os olhos, como se já tivesse visto aquilo antes.",
			"Garota:\n\"O que está acontecendo?\"",
			"Lobo:\n\"A história está se lembrando de você.\"",
			"A tela escurece.",
			"Depois, a floresta aparece em silêncio.",
			"Uma nova carta cai no chão da casa inicial.",
			"Uma nova menina aparece na entrada da floresta.",
			"No chão, nasce outra flor branca.",
		],
		"last_line": "\"Toda receita precisa ser repetida.\"",
	},
	{
		"label": "Ajudar a vovó",
		"description": "Tentar tirar a vovó dali, acreditando que ela também foi manipulada.",
		"ending": "bitter_ending_home",
		"title": "Final amargo - Voltar para casa",
		"image": "res://assets/ui/bitter_ending_home.jpeg",
		"lines": [
			"A garota decide salvar a vovó.",
			"Ela pega a mão da vovó e as duas fogem da casa.",
			"O lobo tenta impedir, mas não as alcança.",
			"As duas conseguem sair.",
			"O lobo fica na porta da casa, observando.",
			"A vovó não olha para trás.",
			"Garota:\n\"Ele vai nos seguir?\"",
			"Vovó:\n\"Ele sempre soube o caminho.\"",
			"A garota percebe que a vovó ainda carrega a maçã escondida.",
			"A floresta não desaparece.",
			"Apenas se fecha atrás delas.",
		],
		"last_line": "\"Nem toda fuga termina fora da floresta.\"",
	},
	{
		"label": "Quebrar a receita",
		"description": "Recusar o ciclo e destruir o que prende a história.",
		"ending": "true_ending_break_recipe",
		"title": "Final verdadeiro - Quebrar a receita",
		"image": "res://assets/ui/final-scene.jpeg",
		"lines": [
			"A garota tira a maçã do centro da receita.",
			"O forno perde o brilho.",
			"O lobo avança, mas a sombra dele falha na parede.",
			"A vovó segura a respiração.",
			"Garota:\n\"Eu não vou terminar uma história que nunca foi minha.\"",
			"A receita se desfaz em cinzas frias.",
			"As flores brancas caem uma a uma.",
			"Pela primeira vez, a sala escondida fica em silêncio.",
		],
		"last_line": "\"Uma história também pode acabar.\"",
	},
]

var _is_transitioning := false
var _is_reading := false
var _choice_active := false
var _ending_active := false
var _selected_choice_index := 0
var _selected_ending_action_index := 0

func _ready() -> void:
	_camera.make_current()
	_interact_prompt.visible = false
	_grandma_shadow.visible = false
	_wolf_shadow.visible = false
	_choice_layer.visible = false
	_ending_layer.visible = false
	_ending_content.visible = false
	_ending_fade.modulate.a = 0.0
	if !bool(get_node("/root/GameState").get("furnace_puzzle_solved")):
		call_deferred("_block_direct_access")
		return

	call_deferred("_start_arrival_sequence")

func _process(_delta: float) -> void:
	if _is_transitioning or _is_reading or _choice_active or _ending_active or _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = _get_available_interactable() != null

func _unhandled_input(event: InputEvent) -> void:
	if _ending_active:
		_handle_ending_input(event)
		return

	if _choice_active:
		_handle_choice_input(event)
		return

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
		{"speaker": "GAROTA", "text": "Vovó..."},
		{"speaker": "VOVÓ", "text": "Você saiu do forno."},
		{"speaker": "GAROTA", "text": "Você sabia?"},
		{"speaker": "VOVÓ", "text": "Eu esperava que não doesse."},
		{"speaker": "GAROTA", "text": "Ele tentou me prender lá dentro."},
		{"speaker": "VOVÓ", "text": "Ele sempre faz isso quando tem medo de perder alguma coisa."},
		{"speaker": "GAROTA", "text": "Perder você?"}
	])
	await get_tree().create_timer(0.75).timeout
	await get_node("/root/DialogManager").start_dialog([
		{"speaker": "GAROTA", "text": "Você e ele..."},
		{"speaker": "VOVÓ", "text": "Eu o conheci antes de você nascer."},
		{"speaker": "GAROTA", "text": "Então a carta era mentira."},
		{"speaker": "VOVÓ", "text": "A carta era um caminho."},
		{"speaker": "GAROTA", "text": "Para mim ou para ele?"},
		{"speaker": "VOVÓ", "text": "Para a história continuar."}
	])
	await get_node("/root/DialogManager").start_dialog([
		"A receita não era só comida.",
		"Era um jeito de fazer a floresta repetir o que já tinha perdido."
	])
	_wolf_shadow.visible = true
	await get_node("/root/DialogManager").start_dialog([
		{"speaker": "LOBO", "text": "Você sempre explica demais."},
		{"speaker": "VOVÓ", "text": "Ela precisava saber."},
		{"speaker": "LOBO", "text": "Você respondeu à carta."},
		{"speaker": "LOBO", "text": "Você saiu do caminho."},
		{"speaker": "LOBO", "text": "Colheu a flor."},
		{"speaker": "LOBO", "text": "Trouxe a maçã."},
		{"speaker": "LOBO", "text": "Entrou no forno."},
		{"speaker": "LOBO", "text": "Faltava apenas aceitar."},
		{"speaker": "GAROTA", "text": "Então eu não aceito."}
	])
	get_node("/root/GameState").set("hidden_room_reveal_completed", true)
	_is_reading = false
	if _can_start_final_choice():
		start_final_choice()

func _can_start_final_choice() -> bool:
	var game_state := get_node("/root/GameState")
	return (
		bool(game_state.get("furnace_puzzle_solved"))
		and bool(game_state.get("hidden_room_reveal_completed"))
	)

func start_final_choice() -> void:
	if !_can_start_final_choice() or _choice_active or _ending_active:
		return

	_choice_active = true
	_selected_choice_index = 0
	_player.set_input_enabled(false)
	_choice_layer.visible = true
	_update_choice_menu()

func _handle_choice_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_left"):
		_selected_choice_index = wrapi(_selected_choice_index - 1, 0, FINAL_CHOICES.size())
		_update_choice_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_right"):
		_selected_choice_index = wrapi(_selected_choice_index + 1, 0, FINAL_CHOICES.size())
		_update_choice_menu()
		get_viewport().set_input_as_handled()
	elif (
		event.is_action_pressed("ui_accept")
		or event.is_action_pressed("interact")
		or event.is_action_pressed("dialog_advance")
	):
		get_viewport().set_input_as_handled()
		_confirm_final_choice()

func _update_choice_menu() -> void:
	for index in _choice_labels.size():
		var choice: Dictionary = FINAL_CHOICES[index]
		var label := _choice_labels[index]
		label.text = str(choice["label"])
		label.modulate = SELECTED_COLOR if index == _selected_choice_index else UNSELECTED_COLOR

	var selected_choice: Dictionary = FINAL_CHOICES[_selected_choice_index]
	_choice_description_label.text = str(selected_choice["description"])

func _confirm_final_choice() -> void:
	if !_choice_active:
		return

	var selected_choice: Dictionary = FINAL_CHOICES[_selected_choice_index]
	get_node("/root/GameState").set("selected_ending", str(selected_choice["ending"]))
	_choice_active = false
	_choice_layer.visible = false
	_show_ending(selected_choice)

func _show_ending(ending: Dictionary) -> void:
	_ending_active = true
	_selected_ending_action_index = 0
	_ending_layer.visible = true
	_ending_content.visible = false
	_ending_fade.modulate.a = 0.0
	_ending_title_label.text = str(ending["title"])
	_ending_text_label.text = _format_narrative_lines(ending["lines"])
	_ending_last_line_label.text = str(ending["last_line"])
	_ending_image.texture = load(str(ending["image"])) as Texture2D
	_update_ending_actions()

	var tween := create_tween()
	tween.tween_property(_ending_fade, "modulate:a", 1.0, 0.55)
	await tween.finished
	_ending_content.visible = true

func _handle_ending_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") or event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		_selected_ending_action_index = 1 - _selected_ending_action_index
		_update_ending_actions()
		get_viewport().set_input_as_handled()
	elif (
		event.is_action_pressed("ui_accept")
		or event.is_action_pressed("interact")
		or event.is_action_pressed("dialog_advance")
	):
		get_viewport().set_input_as_handled()
		_confirm_ending_action()

func _update_ending_actions() -> void:
	for index in _ending_action_labels.size():
		_ending_action_labels[index].modulate = (
			ACTION_SELECTED_COLOR if index == _selected_ending_action_index else ACTION_UNSELECTED_COLOR
		)

func _format_narrative_lines(lines: Array) -> String:
	var formatted_lines: Array[String] = []
	for line in lines:
		formatted_lines.append(str(line))
	return "\n\n".join(formatted_lines)

func _confirm_ending_action() -> void:
	if _selected_ending_action_index == 0:
		get_node("/root/SceneTransition").transition_to(MAIN_MENU_SCENE)
	else:
		get_node("/root/GameState").call("reset_player_health")
		get_node("/root/GameState").call("reset_narrative_progress")
		get_node("/root/InventoryManager").call("reset_inventory")
		get_node("/root/SceneTransition").transition_to(NEW_GAME_SCENE)

func _is_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
