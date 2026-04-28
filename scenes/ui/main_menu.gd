extends Control

@onready var novo_jogo_button: Button = %NovoJogoButton
@onready var sair_button: Button = %SairButton

func _ready() -> void:
	novo_jogo_button.pressed.connect(_on_novo_jogo_pressed)
	sair_button.pressed.connect(_on_sair_pressed)

func _on_novo_jogo_pressed() -> void:
	get_node("/root/SceneTransition").transition_to("res://scenes/levels/bedroom_level.tscn")

func _on_sair_pressed() -> void:
	get_tree().quit()
