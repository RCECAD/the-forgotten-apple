extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D

const GRAVITY = 1000
const SPEED = 120
const JUMP_FORCE = -300
const HURT_INVULNERABILITY := 0.9
const HURT_KNOCKBACK_X := 180.0
const HURT_KNOCKBACK_Y := -180.0

enum State {Idle, Run, Jump, Fall, Get_Down, Stay_Down, Get_Up}

var current_state
var is_player_down
var max_health := 3
var health := max_health
var _hurt_timer := 0.0

func _ready():
	current_state = State.Idle
	is_player_down = false
	add_to_group("player")
	
func _physics_process(delta):
	_update_hurt_timer(delta)
	player_falling(delta)
	player_idle(delta)
	player_run(delta)
	player_jump()
	player_down()
	update_state()
	
	move_and_slide()
	
	player_animations()

func _update_hurt_timer(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)
		animated_sprite_2d.modulate.a = 0.5 if int(Time.get_ticks_msec() / 80) % 2 == 0 else 1.0
	else:
		animated_sprite_2d.modulate.a = 1.0

func player_falling(delta):
	if !is_on_floor():
		velocity.y += GRAVITY * delta

@warning_ignore("unused_parameter")
func player_idle(delta):
	if is_on_floor() and velocity.x == 0 and !is_player_down:
		current_state = State.Idle

@warning_ignore("unused_parameter")
func player_run(delta):
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction != 0:
		current_state = State.Run
		animated_sprite_2d.flip_h = false if direction > 0 else true
		
func player_jump():
	if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = JUMP_FORCE
			current_state = State.Jump
			
func player_get_down():
	if Input.is_action_just_pressed("down") and is_on_floor() and !is_player_down:
			current_state = State.Get_Down
			is_player_down = true
	
func player_stay_down():
	if Input.is_action_pressed("down") and is_player_down:
		current_state = State.Stay_Down
		
func player_get_up():
	if Input.is_action_just_released("down") and is_player_down:
		current_state = State.Get_Up
		is_player_down = false
		
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
			current_state = State.Jump
	elif velocity.x != 0:
		current_state = State.Run
	else:
		current_state = State.Idle

func player_animations():
	if current_state == State.Idle:
		animated_sprite_2d.play("idle")
	elif current_state == State.Run:
		animated_sprite_2d.play("run")
	elif current_state == State.Jump:
		animated_sprite_2d.play("jump")
	elif current_state == State.Fall:
		animated_sprite_2d.play("jump")
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
	if _hurt_timer > 0.0:
		return

	health = maxi(health - amount, 0)
	_hurt_timer = HURT_INVULNERABILITY

	if source_position != Vector2.ZERO:
		var knockback_direction: float = sign(global_position.x - source_position.x)
		if knockback_direction == 0.0:
			knockback_direction = 1.0
		velocity.x = knockback_direction * HURT_KNOCKBACK_X
		velocity.y = HURT_KNOCKBACK_Y

	if health <= 0:
		get_tree().reload_current_scene()
