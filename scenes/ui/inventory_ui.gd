extends CanvasLayer

signal letter_selected
signal apple_selected

@onready var _letter_slot: Button = %LetterSlot
@onready var _white_flower_slot: TextureRect = %WhiteFlowerSlot
@onready var _apple_slot: Button = %AppleSlot
@onready var _empty_label: Label = %EmptyLabel

func _ready() -> void:
	layer = 310
	process_mode = Node.PROCESS_MODE_ALWAYS
	_letter_slot.pressed.connect(letter_selected.emit)
	_apple_slot.pressed.connect(apple_selected.emit)

func set_letter_visible(visible: bool) -> void:
	set_items_visible(visible, false, false)

func set_items_visible(has_letter: bool, has_white_flower: bool, has_apple: bool) -> void:
	_letter_slot.visible = has_letter
	_white_flower_slot.visible = has_white_flower
	_apple_slot.visible = has_apple
	_empty_label.visible = !has_letter and !has_white_flower and !has_apple
