extends Control

@onready var novo_jogo_button: Button = %NovoJogoButton
@onready var sair_button: Button = %SairButton
@onready var _difficulty_label: Label = %DifficultyLabel
@onready var _difficulty_slider: HSlider = %DifficultySlider

func _ready() -> void:
	novo_jogo_button.pressed.connect(_on_novo_jogo_pressed)
	sair_button.pressed.connect(_on_sair_pressed)
	var settings := get_node("/root/GameSettings") as GameSettings
	_difficulty_slider.value = settings.get_difficulty()
	_difficulty_label.text = GameSettings.DIFFICULTY_NAMES[settings.get_difficulty()]
	_difficulty_slider.value_changed.connect(_on_difficulty_changed)

func _on_novo_jogo_pressed() -> void:
	get_node("/root/GameState").call("reset_player_health")
	get_node("/root/SceneTransition").transition_to("res://scenes/levels/bedroom_level.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()

func _on_difficulty_changed(value: float) -> void:
	(get_node("/root/GameSettings") as GameSettings).set_difficulty(int(value))
	_difficulty_label.text = GameSettings.DIFFICULTY_NAMES[int(value)]
