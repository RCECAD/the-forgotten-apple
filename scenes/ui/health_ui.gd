extends Control

@export var apple_texture: Texture2D
@export var apple_size := Vector2(26, 26)
@export var empty_alpha := 0.28

@onready var _apple_row: HBoxContainer = $PanelContainer/MarginContainer/AppleRow

var _player: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	call_deferred("_bind_player")

func _process(_delta: float) -> void:
	if _player == null:
		_bind_player()

func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player == _player:
		return

	_player = player
	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(int(_player.get("health")), int(_player.get("max_health")))
	set_process(false)

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	_ensure_apple_count(max_health)
	for index in range(_apple_row.get_child_count()):
		var apple := _apple_row.get_child(index) as TextureRect
		var apple_color := apple.modulate
		apple_color.a = 1.0 if index < current_health else empty_alpha
		apple.modulate = apple_color

func _ensure_apple_count(count: int) -> void:
	while _apple_row.get_child_count() < count:
		_apple_row.add_child(_create_apple())
	while _apple_row.get_child_count() > count:
		_apple_row.get_child(_apple_row.get_child_count() - 1).queue_free()

func _create_apple() -> TextureRect:
	var apple := TextureRect.new()
	apple.texture = apple_texture
	apple.custom_minimum_size = apple_size
	apple.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	apple.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	apple.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return apple
