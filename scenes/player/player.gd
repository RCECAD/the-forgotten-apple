extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var walking_audio: AudioStreamPlayer2D = get_node_or_null("WalkingAudio") as AudioStreamPlayer2D

const GRAVITY = 1000
const WALK_SPEED = 90.0
const RUN_SPEED = 155.0
const JUMP_FORCE = -300
const MAX_JUMPS := 2
const HURT_INVULNERABILITY := 0.9
const HURT_CONTROL_LOCK := 0.26
const HURT_KNOCKBACK_X := 220.0
const HURT_KNOCKBACK_Y := -220.0
const HURT_BLINK_INTERVAL_MS := 70

enum State {Idle, Walk, Run, Jump, Fall, Get_Down, Stay_Down, Get_Up}

var current_state
var is_player_down
var max_health := 3
var health := max_health
var input_enabled := true
var _hurt_timer := 0.0
var _control_lock_timer := 0.0
var _jumps_remaining := MAX_JUMPS
var _is_dead := false

func _ready():
	current_state = State.Idle
	is_player_down = false
	_jumps_remaining = MAX_JUMPS
	add_to_group("player")
	health_changed.emit(health, max_health)
	
func _physics_process(delta):
	if _is_dead:
		return

	_update_hurt_timer(delta)
	_update_control_lock_timer(delta)
	if is_on_floor():
		_jumps_remaining = MAX_JUMPS
	player_falling(delta)

	if !input_enabled:
		velocity.x = move_toward(velocity.x, 0, RUN_SPEED)
		_update_knockback_state()
	elif _control_lock_timer <= 0.0:
		player_idle(delta)
		player_move(delta)
		player_jump()
		player_down()
		update_state()
	else:
		_update_knockback_state()
	
	move_and_slide()
	_update_walking_audio()
	player_animations()

func _update_hurt_timer(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)
		var blink_on := int(Time.get_ticks_msec() / HURT_BLINK_INTERVAL_MS) % 2 == 0
		animated_sprite_2d.modulate = Color(1.0, 0.35, 0.35, 0.45) if blink_on else Color.WHITE
	else:
		animated_sprite_2d.modulate = Color.WHITE

func _update_control_lock_timer(delta: float) -> void:
	if _control_lock_timer > 0.0:
		_control_lock_timer = maxf(_control_lock_timer - delta, 0.0)

func _update_knockback_state() -> void:
	if !is_on_floor():
		current_state = State.Jump if velocity.y < 0.0 else State.Fall
	elif absf(velocity.x) > 0.1:
		current_state = State.Walk
	else:
		current_state = State.Idle

func _update_walking_audio() -> void:
	if walking_audio == null:
		return

	var is_walking: bool = input_enabled and is_on_floor() and absf(velocity.x) > 0.1 and !is_player_down and _control_lock_timer <= 0.0
	if is_walking:
		if !walking_audio.playing:
			walking_audio.play()
	else:
		if walking_audio.playing:
			walking_audio.stop()

func player_falling(delta):
	if !is_on_floor():
		velocity.y += GRAVITY * delta

@warning_ignore("unused_parameter")
func player_idle(delta):
	if is_on_floor() and velocity.x == 0 and !is_player_down:
		current_state = State.Idle

@warning_ignore("unused_parameter")
func player_move(delta):
	var direction := signf(Input.get_axis("move_left", "move_right"))
	
	if direction:
		var movement_speed := RUN_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
		velocity.x = direction * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, RUN_SPEED)
		
	if direction != 0:
		current_state = State.Run if Input.is_key_pressed(KEY_SHIFT) else State.Walk
		animated_sprite_2d.flip_h = false if direction > 0 else true
		
func player_jump():
	if Input.is_action_just_pressed("jump") and _jumps_remaining > 0:
		velocity.y = JUMP_FORCE
		_jumps_remaining -= 1
		current_state = State.Jump
			
func player_down():
	if Input.is_action_just_pressed("down") and is_on_floor() and !is_player_down:
		current_state = State.Get_Down
		is_player_down = true

	elif Input.is_action_pressed("down") and is_player_down:
		current_state = State.Stay_Down

	elif Input.is_action_just_released("down") and is_player_down:
		current_state = State.Get_Up
		is_player_down = false

func update_state():
	if Input.is_action_pressed("down") and is_on_floor():
		player_down()
	elif !is_on_floor():
		if velocity.y < 0:
			current_state = State.Jump
		else:
			current_state = State.Fall
	elif velocity.x != 0:
		current_state = State.Run if Input.is_key_pressed(KEY_SHIFT) else State.Walk
	else:
		current_state = State.Idle

func player_animations():
	if current_state == State.Idle:
		animated_sprite_2d.play("idle")
	elif current_state == State.Walk:
		animated_sprite_2d.play("walk")
	elif current_state == State.Run:
		animated_sprite_2d.play("run")
	elif current_state == State.Jump:
		animated_sprite_2d.play("jump")
	elif current_state == State.Fall:
		animated_sprite_2d.play("fall")
	elif current_state == State.Get_Down:
		animated_sprite_2d.play("get_down")
	elif current_state == State.Stay_Down:
		animated_sprite_2d.play("stay_down")
	elif current_state == State.Get_Up:
		animated_sprite_2d.play("get_up")

func _on_area_entered(area):
	if area.is_in_group("apple"):
		area.queue_free()

func take_damage(amount: int = 1, source_position: Vector2 = Vector2.ZERO) -> void:
	if _is_dead or _hurt_timer > 0.0:
		return

	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	_hurt_timer = HURT_INVULNERABILITY
	_control_lock_timer = HURT_CONTROL_LOCK

	if source_position != Vector2.ZERO:
		var knockback_direction: float = sign(global_position.x - source_position.x)
		if knockback_direction == 0.0:
			knockback_direction = 1.0
		velocity.x = knockback_direction * HURT_KNOCKBACK_X
		velocity.y = HURT_KNOCKBACK_Y

	if health <= 0:
		_die()

func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	if walking_audio != null and walking_audio.playing:
		walking_audio.stop()
	get_node("/root/SceneTransition").reload_current_scene()

func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if enabled:
		return

	velocity.x = 0.0
	is_player_down = false
	current_state = State.Idle
	if walking_audio != null and walking_audio.playing:
		walking_audio.stop()
