extends Node

@export var audio_group: String = "effects"

func _ready() -> void:
	if audio_group != "":
		add_to_group(audio_group)
	get_node("/root/GameSettings").call("apply_audio")
