extends CharacterBody2D

@export var walk_speed: float = 42.0
@export var acceleration: float = 220.0
@export var gravity: float = 1000.0
@export var vision_range_tiles: float = 24.0
@export var attack_range: float = 22.0
@export var attack_cooldown: float = 1.1
@export var attack_duration: float = 0.55
@export var attack_hit_time: float = 0.28
@export var lose_sight_after: float = 0.8
@export var stop_distance: float = 12.0
@export var one_tile_jump_force: float = -220.0
@export var jump_cooldown: float = 0.35
@export var vision_origin_offset := Vector2(0.0, -22.0)
@export var player_target_offset := Vector2(0.0, -16.0)
@export var vision_collision_mask: int = 3
@export var skeleton_audio_enabled := false:
	set(value):
		skeleton_audio_enabled = value
		_update_skeleton_audio()

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _skeleton_audio: AudioStreamPlayer2D = $SkeletonAudio

const TILE_SIZE := 16.0
const GROUND_COLLISION_MASK := 1

var _target_player: CharacterBody2D
var _last_facing_direction := 1.0
var _time_since_seen := INF
var _attack_cooldown_timer := 0.0
var _attack_timer := 0.0
var _jump_cooldown_timer := 0.0
var _has_hit_during_attack := false

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("skeleton_enemy")
	collision_mask = GROUND_COLLISION_MASK
	floor_snap_length = 4.0
	_update_skeleton_audio()
	_play_animation("idle")

func _physics_process(delta: float) -> void:
	_update_skeleton_audio()
	_attack_cooldown_timer = maxf(_attack_cooldown_timer - delta, 0.0)
	_jump_cooldown_timer = maxf(_jump_cooldown_timer - delta, 0.0)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	_update_target(player, delta)
	_apply_gravity(delta)

	if _attack_timer > 0.0:
		_update_attack(delta)
	else:
		_update_movement(delta)
		_try_start_attack()

	move_and_slide()
	_update_visual_direction()

func _update_target(player: CharacterBody2D, delta: float) -> void:
	if player != null and _can_see_player(player):
		_target_player = player
		_time_since_seen = 0.0
		return

	_time_since_seen += delta
	if _time_since_seen > lose_sight_after:
		_target_player = null

func _apply_gravity(delta: float) -> void:
	if !is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

func _update_movement(delta: float) -> void:
	if _target_player == null or !is_instance_valid(_target_player):
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		_play_animation("idle")
		return

	var horizontal_distance := _target_player.global_position.x - global_position.x
	if absf(horizontal_distance) <= stop_distance:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		_play_animation("idle")
		return

	var direction := signf(horizontal_distance)
	_last_facing_direction = direction
	velocity.x = move_toward(velocity.x, direction * walk_speed, acceleration * delta)
	_try_jump_one_tile(direction)
	_play_animation("walk")

func _try_jump_one_tile(direction: float) -> void:
	if _jump_cooldown_timer > 0.0 or !is_on_floor():
		return
	if _target_player == null or !is_instance_valid(_target_player):
		return

	var player_is_one_tile_above := _target_player.global_position.y < global_position.y - TILE_SIZE * 0.5
	if player_is_one_tile_above and absf(_target_player.global_position.x - global_position.x) <= TILE_SIZE * 2.0:
		_jump()
		return

	if _has_one_tile_step_ahead(direction):
		_jump()

func _jump() -> void:
	velocity.y = one_tile_jump_force
	_jump_cooldown_timer = jump_cooldown

func _has_one_tile_step_ahead(direction: float) -> bool:
	var space_state := get_world_2d().direct_space_state
	var forward := Vector2(direction * (TILE_SIZE * 0.75), 0.0)
	var foot_from := global_position + Vector2(0.0, -8.0)
	var foot_to := foot_from + forward
	var step_from := foot_from + Vector2(0.0, -TILE_SIZE)
	var step_to := step_from + forward

	var foot_query := PhysicsRayQueryParameters2D.create(foot_from, foot_to, GROUND_COLLISION_MASK)
	foot_query.exclude = [get_rid()]
	foot_query.collide_with_areas = false
	foot_query.collide_with_bodies = true

	var step_query := PhysicsRayQueryParameters2D.create(step_from, step_to, GROUND_COLLISION_MASK)
	step_query.exclude = [get_rid()]
	step_query.collide_with_areas = false
	step_query.collide_with_bodies = true

	return !space_state.intersect_ray(foot_query).is_empty() and space_state.intersect_ray(step_query).is_empty()

func _try_start_attack() -> void:
	if _attack_cooldown_timer > 0.0:
		return
	if _target_player == null or !is_instance_valid(_target_player):
		return
	if !_can_hit_player(_target_player):
		return

	_attack_timer = attack_duration
	_has_hit_during_attack = false
	velocity.x = 0.0
	_last_facing_direction = signf(_target_player.global_position.x - global_position.x)
	if _last_facing_direction == 0.0:
		_last_facing_direction = 1.0
	_play_animation("attack")

func _update_attack(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)

	var elapsed := attack_duration - _attack_timer
	if !_has_hit_during_attack and elapsed >= attack_hit_time:
		_has_hit_during_attack = true
		if _target_player != null and is_instance_valid(_target_player) and _can_hit_player(_target_player):
			if _target_player.has_method("take_damage"):
				_target_player.take_damage(1, global_position)

	if _attack_timer <= 0.0:
		_attack_cooldown_timer = attack_cooldown
		_play_animation("idle")

func _can_hit_player(player: CharacterBody2D) -> bool:
	return global_position.distance_to(player.global_position) <= attack_range and _can_see_player(player)

func _can_see_player(player: CharacterBody2D) -> bool:
	var from := global_position + vision_origin_offset
	var to := player.global_position + player_target_offset
	if from.distance_to(to) > vision_range_tiles * TILE_SIZE:
		return false

	var query := PhysicsRayQueryParameters2D.create(from, to, vision_collision_mask)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return !hit.is_empty() and hit.get("collider") == player

func _update_visual_direction() -> void:
	if _attack_timer <= 0.0 and absf(velocity.x) > 0.1:
		_last_facing_direction = signf(velocity.x)
	_animated_sprite.flip_h = _last_facing_direction < 0.0

func _play_animation(animation_name: StringName) -> void:
	if _animated_sprite.animation == animation_name:
		return
	_animated_sprite.play(animation_name)

func _update_skeleton_audio() -> void:
	if _skeleton_audio == null:
		return
	if skeleton_audio_enabled and !_skeleton_audio.playing:
		_skeleton_audio.play()
	elif !skeleton_audio_enabled and _skeleton_audio.playing:
		_skeleton_audio.stop()
