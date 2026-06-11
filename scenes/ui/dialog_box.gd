extends CanvasLayer

signal dialog_finished

@onready var _text_label: RichTextLabel = %TextLabel

var _lines: Array[String] = []
var _line_index := 0
var _can_advance := false
var _finished := false

func _ready() -> void:
	layer = 300
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_dialog(lines: Array) -> void:
	_lines.clear()
	for line in lines:
		_lines.append(str(line))
	_line_index = 0
	_show_current_line()
	await get_tree().process_frame
	_can_advance = true

func _unhandled_input(event: InputEvent) -> void:
	if !_can_advance or _finished or event.is_echo():
		return
	if !event.is_action_pressed("dialog_advance"):
		return

	get_viewport().set_input_as_handled()
	_line_index += 1
	if _line_index < _lines.size():
		_show_current_line()
		return

	_finished = true
	_can_advance = false
	dialog_finished.emit()

func _show_current_line() -> void:
	_text_label.text = _lines[_line_index]
