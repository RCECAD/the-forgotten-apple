extends CanvasLayer

signal letter_selected

@onready var _letter_slot: Button = %LetterSlot
@onready var _empty_label: Label = %EmptyLabel

func _ready() -> void:
	layer = 310
	process_mode = Node.PROCESS_MODE_ALWAYS
	_letter_slot.pressed.connect(letter_selected.emit)

func set_letter_visible(visible: bool) -> void:
	_letter_slot.visible = visible
	_empty_label.visible = !visible
