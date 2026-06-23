extends Node2D

signal puzzle_solved

const BOARD_CENTER := Vector2(386, 360)
const SLOT_OFFSETS := [
	Vector2(-31, -31),
	Vector2(0, -31),
	Vector2(31, -31),
	Vector2(-31, 0),
	Vector2(0, 0),
	Vector2(31, 0),
	Vector2(-31, 31),
	Vector2(0, 31),
	Vector2(31, 31),
]
const CORRECT_SLOT_INDEXES := [1, 2, 3, 4, 5, 6, 7, 8]
const START_POSITIONS := [
	Vector2(846, 196),
	Vector2(940, 196),
	Vector2(846, 294),
	Vector2(940, 294),
	Vector2(846, 392),
	Vector2(940, 392),
	Vector2(846, 490),
	Vector2(940, 490),
]
const SNAP_DISTANCE := 38.0
const PIECE_SCALE := Vector2(2, 2)

const PIECE_TEXTURES := [
	preload("res://assets/ui/puzzle piece 1.png"),
	preload("res://assets/ui/puzzle piece 2.png"),
	preload("res://assets/ui/puzzle piece 3.png"),
	preload("res://assets/ui/puzzle piece 4.png"),
	preload("res://assets/ui/puzzle piece 5.png"),
	preload("res://assets/ui/puzzle piece 6.png"),
	preload("res://assets/ui/puzzle piece 7.png"),
	preload("res://assets/ui/puzzle piece 8.png"),
]

@onready var _timer_label: Label = $TimerLabel
@onready var _slots_root: Node2D = $Slots
@onready var _pieces_root: Node2D = $Pieces

var _slot_nodes: Array[Node2D] = []
var _piece_nodes: Array[Sprite2D] = []
var _dragged_piece: Sprite2D
var _drag_offset := Vector2.ZERO
var _drag_z_index := 10
var _solved := false

func _ready() -> void:
	_build_slots()
	_build_pieces()
	hide()

func start_puzzle() -> void:
	_solved = false
	_dragged_piece = null
	_drag_z_index = 10

	for index in _piece_nodes.size():
		var piece := _piece_nodes[index]
		piece.position = START_POSITIONS[index]
		piece.set_meta("locked", false)
		piece.z_index = index

func set_time_remaining(seconds: int) -> void:
	var clamped_seconds := maxi(seconds, 0)
	var minutes := int(clamped_seconds / 60)
	var remainder := clamped_seconds % 60
	_timer_label.text = "%02d:%02d" % [minutes, remainder]

func _input(event: InputEvent) -> void:
	if !visible or _solved:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_pick_piece(event.position)
		else:
			_release_piece()
	elif event is InputEventMouseMotion and _dragged_piece != null:
		_dragged_piece.global_position = event.position + _drag_offset
		get_viewport().set_input_as_handled()

func _build_slots() -> void:
	for offset in SLOT_OFFSETS:
		var slot := Node2D.new()
		slot.position = BOARD_CENTER + offset * PIECE_SCALE
		_slots_root.add_child(slot)
		_slot_nodes.append(slot)

func _build_pieces() -> void:
	for index in PIECE_TEXTURES.size():
		var piece := Sprite2D.new()
		piece.texture = PIECE_TEXTURES[index]
		piece.position = START_POSITIONS[index]
		piece.scale = PIECE_SCALE
		piece.centered = true
		piece.z_index = index
		piece.set_meta("piece_index", index)
		piece.set_meta("locked", false)
		_pieces_root.add_child(piece)
		_piece_nodes.append(piece)

func _try_pick_piece(mouse_position: Vector2) -> void:
	for index in range(_piece_nodes.size() - 1, -1, -1):
		var piece := _piece_nodes[index]
		if bool(piece.get_meta("locked", false)):
			continue
		if _piece_contains_point(piece, mouse_position):
			_dragged_piece = piece
			_drag_offset = piece.global_position - mouse_position
			_dragged_piece.z_index = _drag_z_index
			_drag_z_index += 1
			get_viewport().set_input_as_handled()
			return

func _release_piece() -> void:
	if _dragged_piece == null:
		return

	var piece_index := int(_dragged_piece.get_meta("piece_index"))
	var correct_slot := _slot_nodes[CORRECT_SLOT_INDEXES[piece_index]]
	if _dragged_piece.global_position.distance_to(correct_slot.global_position) <= SNAP_DISTANCE:
		_dragged_piece.global_position = correct_slot.global_position
		_dragged_piece.set_meta("locked", true)
		_dragged_piece.z_index = 100 + piece_index
		_check_completion()
	else:
		_dragged_piece.position = START_POSITIONS[piece_index]

	_dragged_piece = null
	get_viewport().set_input_as_handled()

func _check_completion() -> void:
	for piece in _piece_nodes:
		if !bool(piece.get_meta("locked", false)):
			return

	_solved = true
	puzzle_solved.emit()

func _piece_contains_point(piece: Sprite2D, point: Vector2) -> bool:
	var texture := piece.texture
	if texture == null:
		return false

	var size := texture.get_size() * piece.scale
	var rect := Rect2(piece.global_position - size * 0.5, size)
	return rect.has_point(point)
