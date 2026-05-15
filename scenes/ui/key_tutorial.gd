extends Control

@export var auto_hide_delay := 10.0
@export var fade_duration := 0.35

const LEFT_KEY := preload("res://assets/textures/keyboard_arrow_left.png")
const RIGHT_KEY := preload("res://assets/textures/keyboard_arrow_right.png")
const UP_KEY := preload("res://assets/textures/keyboard_arrow_up.png")
const DOWN_KEY := preload("res://assets/textures/keyboard_arrow_down.png")
const SPACE_KEY := preload("res://assets/textures/keyboard_space.png")
const CTRL_KEY := preload("res://assets/textures/keyboard_ctrl.png")
const E_KEY := preload("res://assets/textures/keyboard_e.png")

const KEY_SIZE := Vector2(42, 42)
const WIDE_KEY_SIZE := Vector2(86, 42)
const ACTION_COLUMN_WIDTH := 136.0
const MIN_PANEL_WIDTH := 720.0
const MAX_PANEL_WIDTH := 780.0

var _panel: PanelContainer
var _elapsed := 0.0
var _is_hiding := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layout()
	_set_mouse_filter_recursive(self)
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, fade_duration)
	set_process(auto_hide_delay > 0.0)

func _process(delta: float) -> void:
	if _is_hiding:
		return

	_elapsed += delta
	if _elapsed >= auto_hide_delay:
		hide_tutorial()

func _unhandled_input(event: InputEvent) -> void:
	if _is_hiding or !visible:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		hide_tutorial()

func hide_tutorial() -> void:
	if _is_hiding:
		return

	_is_hiding = true
	set_process(false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.finished.connect(func() -> void:
		visible = false
	)

func _build_layout() -> void:
	var safe_area := MarginContainer.new()
	safe_area.anchor_left = 0.0
	safe_area.anchor_right = 1.0
	safe_area.anchor_top = 1.0
	safe_area.anchor_bottom = 1.0
	safe_area.offset_left = 24.0
	safe_area.offset_right = -24.0
	safe_area.offset_top = -150.0
	safe_area.offset_bottom = -18.0
	add_child(safe_area)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	safe_area.add_child(center)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _create_panel_style())
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title := Label.new()
	title.text = "Controles"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.9607843, 0.7411765, 0.36078432, 1.0))
	title.add_theme_font_size_override("font_size", 18)
	content.add_child(title)

	var actions := GridContainer.new()
	actions.columns = 5
	actions.add_theme_constant_override("h_separation", 16)
	actions.add_theme_constant_override("v_separation", 8)
	actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(actions)

	actions.add_child(_create_action_item([LEFT_KEY, RIGHT_KEY], "Mover"))
	actions.add_child(_create_action_item([UP_KEY, SPACE_KEY], "Pular"))
	actions.add_child(_create_action_item([DOWN_KEY], "Abaixar"))
	actions.add_child(_create_action_item([CTRL_KEY], "Correr"))
	actions.add_child(_create_action_item([E_KEY], "Interagir"))

func _create_action_item(textures: Array, label_text: String) -> VBoxContainer:
	var item := VBoxContainer.new()
	item.custom_minimum_size = Vector2(ACTION_COLUMN_WIDTH, 62)
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.add_theme_constant_override("separation", 4)

	var keys := HBoxContainer.new()
	keys.custom_minimum_size = Vector2(ACTION_COLUMN_WIDTH, KEY_SIZE.y)
	keys.alignment = BoxContainer.ALIGNMENT_CENTER
	keys.add_theme_constant_override("separation", 4)
	item.add_child(keys)

	for texture in textures:
		keys.add_child(_create_key_icon(texture))

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(ACTION_COLUMN_WIDTH, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.89411765, 0.85882354, 0.7607843, 1.0))
	label.add_theme_font_size_override("font_size", 13)
	item.add_child(label)

	return item

func _create_key_icon(texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = WIDE_KEY_SIZE if texture == SPACE_KEY else KEY_SIZE
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

func _create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06666667, 0.043137256, 0.03137255, 0.86)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.7058824, 0.4117647, 0.18431373, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style

func _update_layout() -> void:
	if _panel == null:
		return

	var viewport_width := get_viewport_rect().size.x
	var panel_width := clampf(viewport_width * 0.62, MIN_PANEL_WIDTH, MAX_PANEL_WIDTH)
	_panel.custom_minimum_size = Vector2(panel_width, 0.0)

func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		_set_mouse_filter_recursive(child)
