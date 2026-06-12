extends CanvasLayer

signal letter_closed

@onready var _taking_paper_sfx: AudioStreamPlayer = $TakingPaperSfx

var _can_close := false
var _closed := false

func _ready() -> void:
	layer = 320
	process_mode = Node.PROCESS_MODE_ALWAYS
	_taking_paper_sfx.play()
	call_deferred("_enable_close")

func _input(event: InputEvent) -> void:
	if !_can_close or _closed or event.is_echo():
		return
	if !event.is_action_pressed("dialog_advance") and !event.is_action_pressed("ui_cancel"):
		return

	get_viewport().set_input_as_handled()
	_closed = true
	_can_close = false
	letter_closed.emit()

func _enable_close() -> void:
	await get_tree().process_frame
	_can_close = true
