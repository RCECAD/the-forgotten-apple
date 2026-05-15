extends TextureRect

@export var press_scale := Vector2(0.84, 0.84)
@export var release_scale := Vector2.ONE
@export var press_duration := 0.1
@export var release_duration := 0.2
@export var wait_duration := 0.45

var _press_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	resized.connect(_update_pivot)
	visibility_changed.connect(_sync_animation)
	_update_pivot()
	_sync_animation()

func _update_pivot() -> void:
	pivot_offset = size * 0.5

func _sync_animation() -> void:
	if visible:
		_start_press_animation()
	else:
		_stop_press_animation()

func _start_press_animation() -> void:
	_stop_press_animation()
	scale = release_scale
	_press_tween = create_tween().set_loops()
	_press_tween.tween_property(self, "scale", press_scale, press_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(self, "scale", release_scale, release_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_press_tween.tween_interval(wait_duration)

func _stop_press_animation() -> void:
	if _press_tween != null:
		_press_tween.kill()
		_press_tween = null
	scale = release_scale
