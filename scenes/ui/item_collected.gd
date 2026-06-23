extends CanvasLayer

signal presentation_finished

@export var item_texture: Texture2D
@export var item_name := "Carta da vovó"

@onready var _content: Control = $Root/CenterContainer/Content
@onready var _item_texture_rect: TextureRect = %ItemTexture
@onready var _item_name_label: Label = %ItemName

func _ready() -> void:
	layer = 315
	process_mode = Node.PROCESS_MODE_ALWAYS
	if item_texture != null:
		_item_texture_rect.texture = item_texture
	_item_name_label.text = item_name
	_content.modulate.a = 0.0
	_content.scale = Vector2(0.75, 0.75)
	call_deferred("_play_presentation")

func _play_presentation() -> void:
	var show_tween := create_tween().set_parallel(true)
	show_tween.tween_property(_content, "modulate:a", 1.0, 0.2)
	show_tween.tween_property(_content, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK)
	await show_tween.finished
	await get_tree().create_timer(1.0).timeout

	var hide_tween := create_tween()
	hide_tween.tween_property(_content, "modulate:a", 0.0, 0.2)
	await hide_tween.finished
	presentation_finished.emit()
