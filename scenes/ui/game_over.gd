extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const MENU_BOX_TEXTURE := preload("res://assets/ui/menu_box.png")
const MENU_ARROW_TEXTURE := preload("res://assets/ui/menu_arrow.png")

const CARD_SIZE := Vector2(640, 372)
const FADE_DURATION := 0.4
const SELECTION_DURATION := 0.1
const OVERLAY_ALPHA := 0.72
const SELECTED_COLOR := Color(1.0, 0.86, 0.45)
const UNSELECTED_COLOR := Color(0.68, 0.51, 0.29)
const TITLE_COLOR := Color(0.86, 0.36, 0.32)
const FLAVOR_COLOR := Color(0.78, 0.66, 0.52)
const SHADOW_COLOR := Color(0.12, 0.02, 0.02, 0.95)
const ARROW_SIZE := Vector2(34, 34)

var is_active := false

var _overlay: ColorRect
var _card: Control
var _options: Array[Label] = []
var _arrow: TextureRect
var _selected_index := 0
var _is_busy := false
var _selection_tween: Tween

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()
	get_viewport().size_changed.connect(_update_layout)

func show_game_over() -> void:
	if is_active:
		return

	is_active = true
	_freeze_players()
	_is_busy = true
	_selected_index = 0
	visible = true
	get_tree().paused = true
	_update_layout()

	var target_scale := _card.scale
	_arrow.visible = false
	_overlay.color.a = 0.0
	_card.modulate.a = 0.0
	_card.scale = target_scale * 0.94
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_overlay, "color:a", OVERLAY_ALPHA, FADE_DURATION)
	tween.tween_property(_card, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(_card, "scale", target_scale, FADE_DURATION).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	await tween.finished
	_is_busy = false
	_arrow.visible = true
	_update_selection(true)

func _unhandled_input(event: InputEvent) -> void:
	if !is_active or _is_busy or !event.is_pressed() or event.is_echo():
		return

	if _is_up(event):
		_move_selection(-1)
	elif _is_down(event):
		_move_selection(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_confirm_selection()
	else:
		return

	get_viewport().set_input_as_handled()

func _move_selection(direction: int) -> void:
	_selected_index = wrapi(_selected_index + direction, 0, _options.size())
	_update_selection()

func _confirm_selection() -> void:
	if _is_busy:
		return

	_is_busy = true
	get_node("/root/GameState").call("reset_player_health")
	visible = false
	is_active = false
	get_tree().paused = false

	if _selected_index == 0:
		await get_node("/root/SceneTransition").reload_current_scene()
	else:
		await get_node("/root/SceneTransition").transition_to(MAIN_MENU_SCENE)

	_is_busy = false

func _update_selection(skip_animation := false) -> void:
	for index in range(_options.size()):
		_options[index].modulate = (
			SELECTED_COLOR if index == _selected_index else UNSELECTED_COLOR
		)

	if !visible:
		return

	var selected_rect := _options[_selected_index].get_global_rect()
	var target_position := Vector2(
		selected_rect.position.x - _arrow.size.x - 6.0,
		selected_rect.position.y + (selected_rect.size.y - _arrow.size.y) * 0.5
	)

	if _selection_tween != null and _selection_tween.is_valid():
		_selection_tween.kill()

	if skip_animation:
		_arrow.global_position = target_position
		return

	_selection_tween = create_tween()
	_selection_tween.tween_property(
		_arrow, "global_position", target_position, SELECTION_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color(0.04, 0.02, 0.02, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	_card = Control.new()
	_card.name = "Card"
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -CARD_SIZE.x * 0.5
	_card.offset_right = CARD_SIZE.x * 0.5
	_card.offset_top = -CARD_SIZE.y * 0.5
	_card.offset_bottom = CARD_SIZE.y * 0.5
	_card.pivot_offset = CARD_SIZE * 0.5
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)

	var box := TextureRect.new()
	box.name = "MenuBox"
	box.texture = MENU_BOX_TEXTURE
	box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.stretch_mode = TextureRect.STRETCH_SCALE
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.add_child(box)

	var title := Label.new()
	title.text = "Você não resistiu"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 92.0
	title.offset_bottom = 148.0
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(title)

	var flavor := Label.new()
	flavor.text = "A floresta ficou com você."
	flavor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	flavor.add_theme_font_size_override("font_size", 19)
	flavor.add_theme_color_override("font_color", FLAVOR_COLOR)
	flavor.set_anchors_preset(Control.PRESET_TOP_WIDE)
	flavor.offset_top = 150.0
	flavor.offset_bottom = 178.0
	flavor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(flavor)

	var options_box := VBoxContainer.new()
	options_box.name = "Options"
	options_box.alignment = BoxContainer.ALIGNMENT_CENTER
	options_box.add_theme_constant_override("separation", 12)
	options_box.set_anchors_preset(Control.PRESET_CENTER)
	options_box.offset_left = -120.0
	options_box.offset_right = 120.0
	options_box.offset_top = 12.0
	options_box.offset_bottom = 96.0
	options_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(options_box)

	for option_text in ["Tentar novamente", "Menu principal"]:
		var label := Label.new()
		label.text = option_text
		label.custom_minimum_size = Vector2(0, 38)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		options_box.add_child(label)
		_options.append(label)

	_arrow = TextureRect.new()
	_arrow.name = "Arrow"
	_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_arrow.texture = MENU_ARROW_TEXTURE
	_arrow.custom_minimum_size = ARROW_SIZE
	_arrow.size = ARROW_SIZE
	_arrow.pivot_offset = ARROW_SIZE * 0.5
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arrow)

func _freeze_players() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if player.has_method("set_input_enabled"):
			player.set_input_enabled(false)
		if player is CharacterBody2D:
			(player as CharacterBody2D).velocity = Vector2.ZERO

func _update_layout() -> void:
	if _card == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := minf(viewport_size.x / 1280.0, viewport_size.y / 720.0)
	scale_factor = clampf(scale_factor, 0.72, 1.25)
	_card.scale = Vector2.ONE * scale_factor
	_card.pivot_offset = CARD_SIZE * 0.5
	_arrow.scale = Vector2.ONE * scale_factor

	if visible:
		call_deferred("_update_selection", true)

func _is_up(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_up") or _is_key(event, KEY_W)

func _is_down(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_down") or _is_key(event, KEY_S)

func _is_key(event: InputEvent, keycode: Key) -> bool:
	return event is InputEventKey and (event as InputEventKey).physical_keycode == keycode
