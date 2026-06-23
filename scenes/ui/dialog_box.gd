extends CanvasLayer

signal dialog_finished
signal dialog_line_started(entry: Dictionary, index: int)

@export var characters_per_second := 42.0

@onready var _speaker_label: Label = %SpeakerLabel
@onready var _text_label: RichTextLabel = %TextLabel
@onready var _continue_label: Label = %ContinueLabel

var _entries: Array[Dictionary] = []
var _line_index := 0
var _can_advance := false
var _finished := false
var _is_typing := false
var _visible_characters_float := 0.0
var _input_unlock_frame := 0

func _ready() -> void:
	layer = 300
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_dialog(lines: Array) -> void:
	_entries.clear()
	for line in lines:
		if line is Dictionary:
			var entry := (line as Dictionary).duplicate(true)
			entry["speaker"] = str(entry.get("speaker", ""))
			entry["text"] = str(entry.get("text", ""))
			entry["view"] = str(entry.get("view", "normal"))
			_entries.append(entry)
		else:
			_entries.append({
				"speaker": "",
				"text": str(line),
				"view": "normal",
			})
	_line_index = 0
	_show_current_line()
	await get_tree().process_frame
	_can_advance = true
	_input_unlock_frame = Engine.get_process_frames() + 1

func _process(delta: float) -> void:
	if !_is_typing:
		return

	_visible_characters_float += characters_per_second * delta
	_text_label.visible_characters = mini(
		int(_visible_characters_float),
		_text_label.get_total_character_count()
	)
	if _text_label.visible_characters >= _text_label.get_total_character_count():
		_complete_typing()

func _unhandled_input(event: InputEvent) -> void:
	if (
		!_can_advance
		or _finished
		or event.is_echo()
		or Engine.get_process_frames() < _input_unlock_frame
	):
		return
	if !_is_advance_event(event):
		return

	get_viewport().set_input_as_handled()
	if _is_typing:
		_complete_typing()
		return

	_line_index += 1
	if _line_index < _entries.size():
		_show_current_line()
		_input_unlock_frame = Engine.get_process_frames() + 1
		return

	_finished = true
	_can_advance = false
	dialog_finished.emit()

func _show_current_line() -> void:
	var entry := _entries[_line_index]
	var speaker := str(entry.get("speaker", ""))
	_speaker_label.text = speaker
	_speaker_label.visible = !speaker.is_empty()
	_text_label.text = str(entry.get("text", ""))
	_text_label.visible_characters = 0
	_visible_characters_float = 0.0
	_is_typing = true
	_continue_label.modulate.a = 0.45
	dialog_line_started.emit(entry, _line_index)

func _complete_typing() -> void:
	_is_typing = false
	_text_label.visible_characters = -1
	_continue_label.modulate.a = 1.0

func _is_advance_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	return (
		event.is_action_pressed("dialog_advance")
		or event.is_action_pressed("interact")
		or event.is_action_pressed("ui_accept")
	)
