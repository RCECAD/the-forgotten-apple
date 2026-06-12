extends Control

const SELECTED_COLOR := Color(1.0, 0.84, 0.38)
const UNSELECTED_COLOR := Color(0.67, 0.49, 0.27)
const ARROW_GAP := 0.0

@onready var _menu_arrow: TextureRect = %MenuArrow
@onready var _options: Array[Label] = [
	%NovoJogoLabel,
	%ContinuarLabel,
	%ConfiguracoesLabel,
	%SairLabel,
]

var _selected_index := 0

func _ready() -> void:
	call_deferred("_update_selection")

func _input(event: InputEvent) -> void:
	if !event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("ui_up") or _is_key(event, KEY_W):
		_selected_index = wrapi(_selected_index - 1, 0, _options.size())
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or _is_key(event, KEY_S):
		_selected_index = wrapi(_selected_index + 1, 0, _options.size())
		_update_selection()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
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

func _confirm_selection() -> void:
	match _selected_index:
		0:
			_on_novo_jogo_pressed()
		1:
			print("Continuar ainda não implementado")
		2:
			print("Configurações ainda não implementado")
		3:
			_on_sair_pressed()

func _is_key(event: InputEvent, keycode: Key) -> bool:
	return event is InputEventKey and (event as InputEventKey).physical_keycode == keycode

func _on_novo_jogo_pressed() -> void:
	get_node("/root/GameState").call("reset_player_health")
	get_node("/root/GameState").call("reset_narrative_progress")
	get_node("/root/InventoryManager").call("reset_inventory")
	get_node("/root/SceneTransition").transition_to("res://scenes/levels/bedroom_level.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
