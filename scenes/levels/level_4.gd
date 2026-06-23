extends Node2D

const LEVEL_5_SCENE := "res://scenes/levels/level_5.tscn"
const PUZZLE_TIME_LIMIT := 180.0
const RED_STAGE_STEP := 30.0
const RED_STAGE_ALPHAS := [0.0, 0.08, 0.14, 0.2, 0.28, 0.36, 0.46]

@onready var _player: CharacterBody2D = $Player
@onready var _camera: Camera2D = $Camera2D
@onready var _pause_menu: Control = $UI/PauseMenu
@onready var _interact_prompt: Label = $Player/InteractPrompt
@onready var _container_trigger: Area2D = $PuzzleContainer
@onready var _puzzle: Node2D = $PuzzleLayer/PuzzleUI
@onready var _red_overlay: ColorRect = $PuzzleLayer/RedOverlay

var _is_transitioning := false
var _puzzle_active := false
var _puzzle_solved := false
var _time_remaining := PUZZLE_TIME_LIMIT
var _red_stage := 0
var _red_tween: Tween

func _ready() -> void:
	_camera.make_current()
	_interact_prompt.visible = false
	_container_trigger.monitoring = true
	_red_overlay.color.a = 0.0
	_puzzle.hide()
	_puzzle.connect("puzzle_solved", Callable(self, "_on_puzzle_solved"))
	_puzzle.call("set_time_remaining", int(PUZZLE_TIME_LIMIT))

func _process(delta: float) -> void:
	if _puzzle_active:
		_update_puzzle_timer(delta)

	if _is_transitioning or _pause_menu.visible or _is_modal_active():
		_interact_prompt.visible = false
		return

	_interact_prompt.visible = !_puzzle_solved and _container_trigger.overlaps_body(_player)

func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return

	if _puzzle_active:
		return

	if event.is_action_pressed("ui_cancel") and !_pause_menu.visible:
		_pause_menu.open_menu()
		get_viewport().set_input_as_handled()
	elif _pause_menu.visible or _is_other_modal_active():
		return
	elif event.is_action_pressed("interact") and !_puzzle_solved and _container_trigger.overlaps_body(_player):
		get_viewport().set_input_as_handled()
		_open_puzzle()

func _open_puzzle() -> void:
	_puzzle_active = true
	_time_remaining = PUZZLE_TIME_LIMIT
	_red_stage = 0
	_player.set_input_enabled(false)
	_interact_prompt.visible = false
	_set_red_stage(0)
	_puzzle.show()
	_puzzle.call("start_puzzle")
	_puzzle.call("set_time_remaining", int(PUZZLE_TIME_LIMIT))

func _update_puzzle_timer(delta: float) -> void:
	_time_remaining = maxf(_time_remaining - delta, 0.0)
	_puzzle.call("set_time_remaining", int(ceil(_time_remaining)))

	var next_stage := mini(int(floor((PUZZLE_TIME_LIMIT - _time_remaining) / RED_STAGE_STEP)), RED_STAGE_ALPHAS.size() - 1)
	if next_stage != _red_stage:
		_set_red_stage(next_stage)

	if _time_remaining <= 0.0:
		_fail_puzzle()

func _set_red_stage(stage: int) -> void:
	_red_stage = clampi(stage, 0, RED_STAGE_ALPHAS.size() - 1)
	if _red_tween != null and _red_tween.is_valid():
		_red_tween.kill()
	_red_tween = create_tween()
	_red_tween.tween_property(
		_red_overlay,
		"color:a",
		RED_STAGE_ALPHAS[_red_stage],
		0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _fail_puzzle() -> void:
	if !_puzzle_active or _is_transitioning:
		return

	_puzzle_active = false
	_puzzle.hide()
	get_node("/root/GameOver").call("show_game_over")

func _on_puzzle_solved() -> void:
	if _is_transitioning:
		return

	_puzzle_active = false
	_puzzle_solved = true
	_is_transitioning = true
	_puzzle.hide()
	_interact_prompt.visible = false
	await get_tree().create_timer(0.15).timeout
	get_node("/root/SceneTransition").transition_to(LEVEL_5_SCENE)

func _is_modal_active() -> bool:
	return _puzzle_active or _is_other_modal_active()

func _is_other_modal_active() -> bool:
	return (
		get_node("/root/DialogManager").is_dialog_active
		or get_node("/root/InventoryManager").is_inventory_open
		or get_node("/root/LetterViewer").is_letter_open
	)
