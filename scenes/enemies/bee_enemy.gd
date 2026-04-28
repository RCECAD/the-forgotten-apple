extends Area2D

@export var patrol_speed: float = 36.0
@export var chase_speed: float = 72.0
@export var acceleration: float = 260.0
@export var patrol_range: float = 96.0
@export var chase_radius: float = 180.0
@export var chase_stop_radius: float = 28.0
@export var attack_radius: float = 18.0
@export var attack_windup: float = 0.35
@export var attack_cooldown: float = 0.8
@export var hover_offset_x: float = 36.0
@export var hover_offset_y: float = -10.0
@export var strafe_strength: float = 0.55
@export var bob_amplitude: float = 4.0
@export var bob_speed: float = 3.5

@onready var _animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

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
	_animated_sprite_2d.play("fly")

func _physics_process(delta: float) -> void:
	_time += delta
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_windup_timer = maxf(_windup_timer - delta, 0.0)

	var player: CharacterBody2D = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and global_position.distance_to(player.global_position) <= chase_radius:
		_chase_player(player, delta)
		_try_damage_player(player, delta)
	else:
		_is_winding_up = false
		_windup_timer = 0.0
		_patrol(delta)

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
		desired_velocity.x += player.velocity.x * 0.25

	_velocity = _velocity.move_toward(desired_velocity, acceleration * delta)
	global_position += _velocity * delta

	if absf(global_position.x - player.global_position.x) < 32.0 and int(_time * 2.0) % 2 == 0:
		_strafe_direction *= -1.0

	_direction = 1.0 if _velocity.x >= 0.0 else -1.0
	_animated_sprite_2d.flip_h = _direction < 0.0

func _try_damage_player(player: CharacterBody2D, delta: float) -> void:
	if _attack_timer > 0.0:
		_is_winding_up = false
		_windup_timer = 0.0
		return

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player <= attack_radius:
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
