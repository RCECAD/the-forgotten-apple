extends Control

enum MenuState {
	MAIN,
	SETTINGS,
	CONTROLS,
	CONFIRM_MAIN_MENU,
	CONFIRM_EXIT,
}

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SELECTED_COLOR := Color(1.0, 0.86, 0.45)
const UNSELECTED_COLOR := Color(0.68, 0.51, 0.29)
const VALUE_COLOR := Color(0.94, 0.78, 0.42)
const FADE_DURATION := 0.16
const SELECTION_DURATION := 0.1
const VOLUME_STEP := 5.0

@onready var _main_panel: Control = %MainPanel
@onready var _expanded_panel: Control = %ExpandedPanel
@onready var _settings_content: Control = %SettingsContent
@onready var _controls_content: Control = %ControlsContent
@onready var _confirmation_content: Control = %ConfirmationContent
@onready var _selection_arrow: TextureRect = %SelectionArrow

@onready var _main_options: Array[Label] = [
	%ContinueOption,
	%SettingsOption,
	%ControlsOption,
	%MainMenuOption,
	%ExitOption,
]
@onready var _settings_rows: Array[Control] = [
	%MasterRow,
	%MusicRow,
	%EffectsRow,
	%DisplayModeRow,
	%ResolutionRow,
	%SettingsBackRow,
]
@onready var _settings_labels: Array[Label] = [
	%MasterLabel,
	%MusicLabel,
	%EffectsLabel,
	%DisplayModeLabel,
	%ResolutionLabel,
	%SettingsBackLabel,
]
@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _effects_slider: HSlider = %EffectsSlider
@onready var _master_value: Label = %MasterValue
@onready var _music_value: Label = %MusicValue
@onready var _effects_value: Label = %EffectsValue
@onready var _display_mode_value: Label = %DisplayModeValue
@onready var _resolution_value: Label = %ResolutionValue
@onready var _controls_back_row: Control = %ControlsBackRow
@onready var _controls_back_label: Label = %ControlsBackLabel
@onready var _confirmation_message: Label = %ConfirmationMessage
@onready var _button_selection_sfx: AudioStreamPlayer = $ButtonSelectionSfx
@onready var _button_selected_sfx: AudioStreamPlayer = $ButtonSelectedSfx
@onready var _confirmation_options: Array[Label] = [
	%ConfirmationYes,
	%ConfirmationNo,
]

var _state := MenuState.MAIN
var _selected_index := 0
var _is_animating := false
var _settings_only := false
var _pause_tree_on_open := true
var _selection_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_master_slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_music_slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effects_slider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()

func open_menu() -> void:
	_open_with_state(MenuState.MAIN, true, false)

func open_settings_menu() -> void:
	_open_with_state(MenuState.SETTINGS, false, true)

func _open_with_state(initial_state: MenuState, should_pause_tree: bool, settings_only: bool) -> void:
	if visible:
		return

	_pause_tree_on_open = should_pause_tree
	_settings_only = settings_only
	if _pause_tree_on_open:
		get_tree().paused = true
	visible = true
	_state = initial_state
	_selected_index = 0
	_sync_from_settings()
	_show_current_state()
	_update_layout()
	modulate.a = 0.0
	_is_animating = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished
	_is_animating = false

func close_menu() -> void:
	if !visible or _is_animating:
		return

	_is_animating = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	visible = false
	modulate.a = 1.0
	if _pause_tree_on_open:
		get_tree().paused = false
	_settings_only = false
	_pause_tree_on_open = true
	_is_animating = false

func _unhandled_input(event: InputEvent) -> void:
	if !visible or _is_animating or !event.is_pressed() or event.is_echo():
		return

	if event.is_action_pressed("ui_cancel"):
		_play_button_selected_sfx()
		_handle_back()
	elif _is_up(event):
		_move_selection(-1)
	elif _is_down(event):
		_move_selection(1)
	elif _state == MenuState.SETTINGS and _is_left(event):
		_play_button_selection_sfx()
		_adjust_setting(-1)
	elif _state == MenuState.SETTINGS and _is_right(event):
		_play_button_selection_sfx()
		_adjust_setting(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_play_button_selected_sfx()
		_confirm_selection()
	else:
		return

	get_viewport().set_input_as_handled()

func _handle_back() -> void:
	if _settings_only:
		close_menu()
	elif _state == MenuState.MAIN:
		close_menu()
	else:
		_show_main()

func _move_selection(direction: int) -> void:
	var option_count := _get_option_count()
	_selected_index = wrapi(_selected_index + direction, 0, option_count)
	_play_button_selection_sfx()
	_update_selection()

func _confirm_selection() -> void:
	match _state:
		MenuState.MAIN:
			_confirm_main_option()
		MenuState.SETTINGS:
			_confirm_settings_option()
		MenuState.CONTROLS:
			_show_main()
		MenuState.CONFIRM_MAIN_MENU:
			if _selected_index == 0:
				_go_to_main_menu()
			else:
				_show_main()
		MenuState.CONFIRM_EXIT:
			if _selected_index == 0:
				get_tree().quit()
			else:
				_show_main()

func _confirm_main_option() -> void:
	match _selected_index:
		0:
			close_menu()
		1:
			_show_settings()
		2:
			_show_controls()
		3:
			_show_confirmation(MenuState.CONFIRM_MAIN_MENU)
		4:
			_show_confirmation(MenuState.CONFIRM_EXIT)

func _confirm_settings_option() -> void:
	match _selected_index:
		3:
			_toggle_fullscreen()
		4:
			_cycle_resolution(1)
		5:
			if _settings_only:
				close_menu()
			else:
				_show_main()

func _adjust_setting(direction: int) -> void:
	var settings := get_node("/root/GameSettings")
	match _selected_index:
		0:
			settings.call(
				"set_master_volume_percent",
				float(settings.call("get_master_volume_percent")) + VOLUME_STEP * direction
			)
		1:
			settings.call(
				"set_music_volume_percent",
				float(settings.call("get_music_volume_percent")) + VOLUME_STEP * direction
			)
		2:
			settings.call(
				"set_effects_volume_percent",
				float(settings.call("get_effects_volume_percent")) + VOLUME_STEP * direction
			)
		3:
			_toggle_fullscreen()
		4:
			_cycle_resolution(direction)
	_sync_from_settings()
	_update_selection()

func _toggle_fullscreen() -> void:
	var settings := get_node("/root/GameSettings")
	settings.call("set_fullscreen_enabled", !bool(settings.call("is_fullscreen_enabled")))
	_sync_from_settings()

func _cycle_resolution(direction: int) -> void:
	var settings := get_node("/root/GameSettings")
	var current_index := int(settings.call("get_window_preset_index"))
	var preset_count := int(settings.call("get_window_preset_count"))
	settings.call(
		"set_window_preset_index",
		wrapi(current_index + direction, 0, preset_count)
	)
	_sync_from_settings()

func _show_main() -> void:
	_state = MenuState.MAIN
	_selected_index = 0
	_show_current_state()

func _show_settings() -> void:
	_state = MenuState.SETTINGS
	_selected_index = 0
	_sync_from_settings()
	_show_current_state()

func _show_controls() -> void:
	_state = MenuState.CONTROLS
	_selected_index = 0
	_show_current_state()

func _show_confirmation(state: MenuState) -> void:
	_state = state
	_selected_index = 1
	if state == MenuState.CONFIRM_MAIN_MENU:
		_confirmation_message.text = (
			"Deseja voltar ao menu principal?\n"
			+ "O progresso não salvo poderá ser perdido."
		)
	else:
		_confirmation_message.text = "Deseja realmente sair do jogo?"
	_show_current_state()

func _show_current_state() -> void:
	_main_panel.visible = _state == MenuState.MAIN
	_expanded_panel.visible = _state != MenuState.MAIN
	_settings_content.visible = _state == MenuState.SETTINGS
	_controls_content.visible = _state == MenuState.CONTROLS
	_confirmation_content.visible = (
		_state == MenuState.CONFIRM_MAIN_MENU
		or _state == MenuState.CONFIRM_EXIT
	)
	call_deferred("_update_selection")

func _update_selection() -> void:
	if !visible:
		return

	for index in range(_main_options.size()):
		_main_options[index].modulate = (
			SELECTED_COLOR if _state == MenuState.MAIN and index == _selected_index
			else UNSELECTED_COLOR
		)
	for index in range(_settings_labels.size()):
		_settings_labels[index].modulate = (
			SELECTED_COLOR if _state == MenuState.SETTINGS and index == _selected_index
			else UNSELECTED_COLOR
		)
	_controls_back_label.modulate = (
		SELECTED_COLOR if _state == MenuState.CONTROLS else UNSELECTED_COLOR
	)
	for index in range(_confirmation_options.size()):
		_confirmation_options[index].modulate = (
			SELECTED_COLOR
			if _state in [MenuState.CONFIRM_MAIN_MENU, MenuState.CONFIRM_EXIT]
			and index == _selected_index
			else UNSELECTED_COLOR
		)

	var selected_control := _get_selected_control()
	var selected_rect := selected_control.get_global_rect()
	var target_position := Vector2(
		selected_rect.position.x - _selection_arrow.size.x - 8.0,
		selected_rect.position.y + (selected_rect.size.y - _selection_arrow.size.y) * 0.5
	)
	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()
	_selection_tween = create_tween()
	_selection_tween.tween_property(
		_selection_arrow,
		"global_position",
		target_position,
		SELECTION_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _get_selected_control() -> Control:
	match _state:
		MenuState.MAIN:
			return _main_options[_selected_index]
		MenuState.SETTINGS:
			return _settings_rows[_selected_index]
		MenuState.CONTROLS:
			return _controls_back_row
		_:
			return _confirmation_options[_selected_index]

func _get_option_count() -> int:
	match _state:
		MenuState.MAIN:
			return _main_options.size()
		MenuState.SETTINGS:
			return _settings_rows.size()
		MenuState.CONTROLS:
			return 1
		_:
			return _confirmation_options.size()

func _sync_from_settings() -> void:
	var settings := get_node("/root/GameSettings")
	var master := float(settings.call("get_master_volume_percent"))
	var music := float(settings.call("get_music_volume_percent"))
	var effects := float(settings.call("get_effects_volume_percent"))
	_master_slider.value = master
	_music_slider.value = music
	_effects_slider.value = effects
	_master_value.text = "%d%%" % int(round(master))
	_music_value.text = "%d%%" % int(round(music))
	_effects_value.text = "%d%%" % int(round(effects))
	_display_mode_value.text = (
		"Tela cheia" if bool(settings.call("is_fullscreen_enabled")) else "Janela"
	)
	var resolution_index := int(settings.call("get_window_preset_index"))
	_resolution_value.text = str(settings.call("get_window_preset_label", resolution_index))
	_master_value.modulate = VALUE_COLOR
	_music_value.modulate = VALUE_COLOR
	_effects_value.modulate = VALUE_COLOR
	_display_mode_value.modulate = VALUE_COLOR
	_resolution_value.modulate = VALUE_COLOR

func _go_to_main_menu() -> void:
	visible = false
	get_tree().paused = false
	get_node("/root/SceneTransition").transition_to(MAIN_MENU_SCENE)

func _play_button_selection_sfx() -> void:
	_button_selection_sfx.stop()
	_button_selection_sfx.play()

func _play_button_selected_sfx() -> void:
	_button_selected_sfx.stop()
	_button_selected_sfx.play()

func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var scale_factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	scale_factor = clampf(scale_factor, 0.72, 1.25)
	_main_panel.scale = Vector2.ONE * scale_factor
	_expanded_panel.scale = Vector2.ONE * scale_factor
	_main_panel.pivot_offset = _main_panel.size * 0.5
	_expanded_panel.pivot_offset = _expanded_panel.size * 0.5
	if visible:
		call_deferred("_update_selection")

func _is_up(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_up") or _is_key(event, KEY_W)

func _is_down(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_down") or _is_key(event, KEY_S)

func _is_left(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_left") or _is_key(event, KEY_A)

func _is_right(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_right") or _is_key(event, KEY_D)

func _is_key(event: InputEvent, keycode: Key) -> bool:
	return event is InputEventKey and (event as InputEventKey).physical_keycode == keycode
