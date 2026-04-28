extends CanvasLayer

const FADE_DURATION := 0.35

var _is_transitioning := false
var _fade_rect: ColorRect

func _ready() -> void:
	layer = 100

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate = Color(1, 1, 1, 0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade_rect)

func transition_to(scene_path: String) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true
	await _fade_to(1.0)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await _fade_to(0.0)
	_is_transitioning = false

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_DURATION)
	await tween.finished
