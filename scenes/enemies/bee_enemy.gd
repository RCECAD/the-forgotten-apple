extends Area2D

@export var patrol_speed: float = 24.0
@export var chase_speed: float = 44.0
@export var acceleration: float = 120.0
@export var patrol_range: float = 96.0
@export var chase_radius: float = 140.0
@export var chase_stop_radius: float = 12.0
@export var attack_radius: float = 30.0
@export var attack_windup: float = 0.45
@export var attack_cooldown: float = 1.25
@export var hover_offset_x: float = 20.0
@export var hover_offset_y: float = -6.0
@export var strafe_strength: float = 0.15
@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 2.6
@export var forget_radius: float = 180.0
@export var return_threshold: float = 4.0

@onready var _animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var _buzz_audio: AudioStreamPlayer2D = $BeeBuzzAudio

var _start_position: Vector2
var _direction := 1.0
var _time := 0.0
var _attack_timer := 0.0
var _windup_timer := 0.0
var _is_winding_up := false
var _velocity := Vector2.ZERO
var _strafe_direction := 1.0

func _ready() -> void:
	_start_position = global_position
	monitoring = true
	_buzz_audio.play()
	_animated_sprite_2d.play("fly")

func _physics_process(delta: float) -> void:
	_time += delta
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_windup_timer = maxf(_windup_timer - delta, 0.0)

	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if global_position.distance_to(_start_position) > forget_radius:
		_is_winding_up = false
		_windup_timer = 0.0
		_return_home(delta)
	elif player and global_position.distance_to(player.global_position) <= chase_radius:
		_chase_player(player, delta)
		_try_damage_player(player)
	else:
		_is_winding_up = false
		_windup_timer = 0.0
		_patrol(delta)

	_snap_visual()

func _patrol(delta: float) -> void:
	var target_position := Vector2(
		_start_position.x + _direction * patrol_range * 0.5,
		_start_position.y + sin(_time * bob_speed) * bob_amplitude
	)
	_velocity = _velocity.move_toward((target_position - global_position).normalized() * patrol_speed, acceleration * delta)
	global_position += _velocity * delta

	if global_position.x > _start_position.x + patrol_range * 0.5:
		_direction = -1.0
	elif global_position.x < _start_position.x - patrol_range * 0.5:
		_direction = 1.0

	_animated_sprite_2d.flip_h = _velocity.x < 0.0

func _return_home(delta: float) -> void:
	var to_home := _start_position - global_position
	if to_home.length() <= return_threshold:
		global_position = _start_position
		_velocity = Vector2.ZERO
		_direction = 1.0
		_strafe_direction = 1.0
		_animated_sprite_2d.flip_h = false
		return

	_velocity = _velocity.move_toward(to_home.normalized() * patrol_speed, acceleration * delta)
	global_position += _velocity * delta
	_direction = 1.0 if _velocity.x >= 0.0 else -1.0
	_animated_sprite_2d.flip_h = _direction < 0.0

func _chase_player(player: CharacterBody2D, delta: float) -> void:
	var side_bias: float = _strafe_direction * strafe_strength
	var preferred_position: Vector2 = player.global_position + Vector2(
		hover_offset_x * _direction + side_bias * hover_offset_x,
		hover_offset_y + sin(_time * bob_speed) * bob_amplitude
	)
	var to_target := preferred_position - global_position
	var distance := to_target.length()
	var desired_velocity := Vector2.ZERO

	if distance > chase_stop_radius:
		desired_velocity = to_target.normalized() * chase_speed
		desired_velocity.x += player.velocity.x * 0.1

	_velocity = _velocity.move_toward(desired_velocity, acceleration * delta)
	global_position += _velocity * delta

	if absf(global_position.x - player.global_position.x) < 32.0 and int(_time * 2.0) % 2 == 0:
		_strafe_direction *= -1.0

	_direction = 1.0 if _velocity.x >= 0.0 else -1.0
	_animated_sprite_2d.flip_h = _direction < 0.0

func _try_damage_player(player: CharacterBody2D) -> void:
	if _attack_timer > 0.0:
		_is_winding_up = false
		_windup_timer = 0.0
		return

	if _is_player_in_attack_range(player):
		if !_is_winding_up:
			_is_winding_up = true
			_windup_timer = attack_windup
			return

		if _windup_timer > 0.0:
			return

		if player.has_method("take_damage"):
			player.take_damage(1, global_position)
			_attack_timer = attack_cooldown
			_is_winding_up = false
			_windup_timer = 0.0
	else:
		_is_winding_up = false
		_windup_timer = 0.0

func _is_player_in_attack_range(player: CharacterBody2D) -> bool:
	return overlaps_body(player) or global_position.distance_to(player.global_position) <= attack_radius

func _snap_visual() -> void:
	_animated_sprite_2d.global_position = global_position.round() + Vector2(0, -4)
