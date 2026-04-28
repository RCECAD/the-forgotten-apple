extends Control

@onready var _resume_button: Button = %ResumeButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _music_slider: HSlider = %MusicSlider
@onready var _enemy_slider: HSlider = %EnemySlider
@onready var _effects_slider: HSlider = %EffectsSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheckButton
@onready var _resolution_option: OptionButton = %ResolutionOption
@onready var _music_value_label: Label = %MusicValueLabel
@onready var _enemy_value_label: Label = %EnemyValueLabel
@onready var _effects_value_label: Label = %EffectsValueLabel
@onready var _panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var _tab_container: TabContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const MIN_PANEL_WIDTH := 200.0
const MAX_PANEL_WIDTH := 280.0
const MIN_PANEL_HEIGHT := 180.0
const MAX_PANEL_HEIGHT := 240.0
const MENU_SCALE := 0.58

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	get_viewport().size_changed.connect(_update_layout)
	_build_resolution_options()
	_connect_signals()
	_sync_from_settings()
	_update_layout()

func open_menu() -> void:
	if visible:
		return

	visible = true
	get_tree().paused = true
	_sync_from_settings()
	_update_layout()
	_resume_button.grab_focus()

func close_menu() -> void:
	if !visible:
		return

	visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if !visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

func _connect_signals() -> void:
	_resume_button.pressed.connect(close_menu)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_music_slider.value_changed.connect(_on_music_value_changed)
	_enemy_slider.value_changed.connect(_on_enemy_value_changed)
	_effects_slider.value_changed.connect(_on_effects_value_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_resolution_option.item_selected.connect(_on_resolution_selected)

func _update_layout() -> void:
	var viewport_size := get_viewport_rect().size
	scale = Vector2.ONE * MENU_SCALE
	var panel_width := clampf(viewport_size.x * 0.42, MIN_PANEL_WIDTH, MAX_PANEL_WIDTH)
	var panel_height := clampf(viewport_size.y * 0.44, MIN_PANEL_HEIGHT, MAX_PANEL_HEIGHT)
	_panel_container.custom_minimum_size = Vector2(panel_width, panel_height)
	_tab_container.custom_minimum_size = Vector2(0, clampf(viewport_size.y * 0.14, 84.0, 120.0))

func _sync_from_settings() -> void:
	var settings: Node = get_node("/root/GameSettings")
	_music_slider.set_block_signals(true)
	_enemy_slider.set_block_signals(true)
	_effects_slider.set_block_signals(true)
	_fullscreen_check.set_block_signals(true)
	_resolution_option.set_block_signals(true)

	_music_slider.value = float(settings.call("get_music_volume_percent"))
	_enemy_slider.value = float(settings.call("get_enemy_volume_percent"))
	_effects_slider.value = float(settings.call("get_effects_volume_percent"))
	_fullscreen_check.button_pressed = bool(settings.call("is_fullscreen_enabled"))
	_resolution_option.select(int(settings.call("get_window_preset_index")))
	_update_value_labels()

	_music_slider.set_block_signals(false)
	_enemy_slider.set_block_signals(false)
	_effects_slider.set_block_signals(false)
	_fullscreen_check.set_block_signals(false)
	_resolution_option.set_block_signals(false)

func _build_resolution_options() -> void:
	var settings: Node = get_node("/root/GameSettings")
	_resolution_option.clear()
	for index in range(3):
		_resolution_option.add_item(str(settings.call("get_window_preset_label", index)), index)

func _on_music_value_changed(value: float) -> void:
	get_node("/root/GameSettings").call("set_music_volume_percent", value)
	_update_value_labels()

func _on_enemy_value_changed(value: float) -> void:
	get_node("/root/GameSettings").call("set_enemy_volume_percent", value)
	_update_value_labels()

func _on_effects_value_changed(value: float) -> void:
	get_node("/root/GameSettings").call("set_effects_volume_percent", value)
	_update_value_labels()

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	get_node("/root/GameSettings").call("set_fullscreen_enabled", button_pressed)

func _on_resolution_selected(index: int) -> void:
	get_node("/root/GameSettings").call("set_window_preset_index", index)

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_node("/root/SceneTransition").transition_to(MAIN_MENU_SCENE)

func _update_value_labels() -> void:
	_music_value_label.text = "%d%%" % int(round(_music_slider.value))
	_enemy_value_label.text = "%d%%" % int(round(_enemy_slider.value))
	_effects_value_label.text = "%d%%" % int(round(_effects_slider.value))
