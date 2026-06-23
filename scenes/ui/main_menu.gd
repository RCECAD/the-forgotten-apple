extends Control

const SELECTED_COLOR := Color(1.0, 0.84, 0.38)
const UNSELECTED_COLOR := Color(0.67, 0.49, 0.27)
const ARROW_GAP := 0.0
const DEV_SELECTED_COLOR := Color(0.95, 0.92, 0.68)
const DEV_UNSELECTED_COLOR := Color(0.78, 0.67, 0.48)
const DEV_LEVELS := [
	{"label": "Bedroom", "scene": "res://scenes/levels/bedroom_level.tscn"},
	{"label": "Kitchen", "scene": "res://scenes/levels/kitchen_level.tscn"},
	{"label": "Level 1", "scene": "res://scenes/levels/level_1.tscn"},
	{"label": "Cabin", "scene": "res://scenes/levels/cabin_level.tscn"},
	{"label": "Tend", "scene": "res://scenes/levels/tend_level.tscn"},
	{"label": "Level 2", "scene": "res://scenes/levels/level_2.tscn"},
]

@onready var _menu_arrow: TextureRect = %MenuArrow
@onready var _options: Array[Label] = [
	%NovoJogoLabel,
	%ContinuarLabel,
	%ConfiguracoesLabel,
	%SairLabel,
]
@onready var _dev_menu: Control = %DevMenu
@onready var _dev_menu_arrow: TextureRect = %DevMenuArrow
@onready var _music_sound: AudioStreamPlayer = $MusicSound
@onready var _button_selection_sfx: AudioStreamPlayer = $ButtonSelectionSfx
@onready var _button_selected_sfx: AudioStreamPlayer = $ButtonSelectedSfx
@onready var _settings_menu: Control = %SettingsMenu
@onready var _dev_options: Array[Label] = [
	%DevBedroomLabel,
	%DevKitchenLabel,
	%DevLevel1Label,
	%DevCabinLabel,
	%DevTendLabel,
	%DevLevel2Label,
]

var _selected_index := 0
var _dev_selected_index := 0
var _dev_menu_open := false

func _ready() -> void:
	_dev_menu.visible = false
	_music_sound.play()
	call_deferred("_update_selection")
	call_deferred("_update_dev_selection")

func _input(event: InputEvent) -> void:
	if _settings_menu.visible:
		return

	if !event.is_pressed() or event.is_echo():
		return

	if _is_key(event, KEY_F3):
		_toggle_dev_menu()
		get_viewport().set_input_as_handled()
		return

	if _dev_menu_open:
		if event.is_action_pressed("ui_up") or _is_key(event, KEY_W):
			_dev_selected_index = wrapi(_dev_selected_index - 1, 0, _dev_options.size())
			_play_button_selection_sfx()
			_update_dev_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down") or _is_key(event, KEY_S):
			_dev_selected_index = wrapi(_dev_selected_index + 1, 0, _dev_options.size())
			_play_button_selection_sfx()
			_update_dev_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			_play_button_selected_sfx()
			_confirm_dev_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			_toggle_dev_menu(false)
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_up") or _is_key(event, KEY_W):
		_selected_index = wrapi(_selected_index - 1, 0, _options.size())
		_play_button_selection_sfx()
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or _is_key(event, KEY_S):
		_selected_index = wrapi(_selected_index + 1, 0, _options.size())
		_play_button_selection_sfx()
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_play_button_selected_sfx()
		_confirm_selection()
		get_viewport().set_input_as_handled()

func _update_selection() -> void:
	for index in range(_options.size()):
		_options[index].modulate = SELECTED_COLOR if index == _selected_index else UNSELECTED_COLOR

	var selected_label := _options[_selected_index]
	var label_rect := selected_label.get_global_rect()
	_menu_arrow.global_position = Vector2(
		label_rect.position.x - _menu_arrow.size.x - ARROW_GAP,
		label_rect.position.y + (label_rect.size.y - _menu_arrow.size.y) * 0.5
	)

func _update_dev_selection() -> void:
	_dev_menu.visible = _dev_menu_open
	if !_dev_menu_open:
		return

	for index in range(_dev_options.size()):
		_dev_options[index].modulate = (
			DEV_SELECTED_COLOR if index == _dev_selected_index else DEV_UNSELECTED_COLOR
		)

	var selected_label := _dev_options[_dev_selected_index]
	var label_rect := selected_label.get_global_rect()
	_dev_menu_arrow.global_position = Vector2(
		label_rect.position.x - _dev_menu_arrow.size.x - 12.0,
		label_rect.position.y + (label_rect.size.y - _dev_menu_arrow.size.y) * 0.5
	)

func _toggle_dev_menu(open_state = null) -> void:
	if open_state == null:
		_dev_menu_open = !_dev_menu_open
	else:
		_dev_menu_open = bool(open_state)

	if !_dev_menu_open:
		_dev_menu.visible = false
		return

	_dev_selected_index = clampi(_dev_selected_index, 0, _dev_options.size() - 1)
	_dev_menu.visible = true
	_update_dev_selection()

func _confirm_dev_selection() -> void:
	var selected: Dictionary = DEV_LEVELS[_dev_selected_index]
	get_node("/root/GameState").call("reset_player_health")
	get_node("/root/GameState").call("reset_narrative_progress")
	get_node("/root/InventoryManager").call("reset_inventory")
	get_node("/root/SceneTransition").transition_to(str(selected["scene"]))

func _confirm_selection() -> void:
	match _selected_index:
		0:
			_on_novo_jogo_pressed()
		1:
			print("Continuar ainda não implementado")
		2:
			_settings_menu.call("open_settings_menu")
		3:
			_on_sair_pressed()

func _play_button_selection_sfx() -> void:
	_button_selection_sfx.stop()
	_button_selection_sfx.play()

func _play_button_selected_sfx() -> void:
	_button_selected_sfx.stop()
	_button_selected_sfx.play()

func _is_key(event: InputEvent, keycode: Key) -> bool:
	return event is InputEventKey and (event as InputEventKey).physical_keycode == keycode

func _on_novo_jogo_pressed() -> void:
	get_node("/root/GameState").call("reset_player_health")
	get_node("/root/GameState").call("reset_narrative_progress")
	get_node("/root/InventoryManager").call("reset_inventory")
	get_node("/root/SceneTransition").transition_to("res://scenes/levels/bedroom_level.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
