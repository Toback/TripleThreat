class_name JumpState extends State

@export var JUMP_SPEED := -250.0
var jumping: bool
var jump_speed: float
var desired_velocity: float
var input_x: float
var input_jump: bool
var current_gravity: float
var max_speed_change
@export var JUMP_GRAVITY := 400.0
@export var FALL_GRAVITY := 1200.0
@export var SPEED_TO_MAX_GRAVITY := 500.0

@export var MAX_AIR_ACCELERATION := 1200.0
@export var MAX_AIR_DECELERATION := 300.0
@export var MAX_AIR_TURN_SPEED := 1200.0
@export var AIR_SPEED := 140.0 

@export var TERMINAL_DOWN_VELOCITY := 220.0
@export var TERMINAL_UP_VELOCITY := -180.0

var attempt_jump

func enter() -> void:
	print("jump")
	animated_sprite.play("jump")
	state_label.text = "jump"
	jumping = true
	if attempt_jump:
		body.grounded = false
		_jump()
	
func do(delta: float) -> void:	
	_handle_animation()
	input_x = input.get_movement_direction().x
	input_jump = input.wants_jump()
	if body.grounded or (!body.grounded and !jumping):
		is_complete = true

func physics_do(delta: float) -> void:
	body.freeVelocity.y += gravity() * delta
	
	# Clamp player's fall
	body.freeVelocity.y = min(body.freeVelocity.y, TERMINAL_DOWN_VELOCITY)
	
	if input_x != 0:
		if(sign(input_x) != sign(body.freeVelocity.x) ):
			max_speed_change = MAX_AIR_TURN_SPEED * delta
		else:
			max_speed_change = MAX_AIR_ACCELERATION * delta
	else:
		max_speed_change = MAX_AIR_DECELERATION * delta
		
	desired_velocity = input_x * AIR_SPEED
	body.freeVelocity.x = move_toward(body.freeVelocity.x, desired_velocity, max_speed_change)

func _jump() -> void:
	body.freeVelocity.y = JUMP_SPEED

func exit() -> void:
	jumping = false
	
func gravity() -> float:
	# check if our character is going up. Godot has UP being negative y.
	if body.freeVelocity.y < 0.0 :
		# hold the jump button down to jump higher 
		if input_jump:
			current_gravity = JUMP_GRAVITY
			return JUMP_GRAVITY 
			# when you let go of the jump button while rising, you fall down at a faster fall gravity
		else:
			# Ease to the max fall gravity. Can set SPEED_TO_MAX_GRAVITY really high to just
			# go immediately to the fallGravity speed
			current_gravity = move_toward(current_gravity, FALL_GRAVITY, SPEED_TO_MAX_GRAVITY)
			#currentGravity = fallGravity
			return current_gravity
	# once you start falling, fall down faster
	else:
		current_gravity = FALL_GRAVITY
		return current_gravity
		
	return FALL_GRAVITY
	
func _handle_animation() -> void:
	var anim_time: float = Helpers.map(body.velocity.y, jump_speed, -jump_speed, 0, 1, true)
	var total_frames: int = animated_sprite.sprite_frames.get_frame_count("jump")
	var frame_index = int(anim_time * (total_frames - 1))
	animated_sprite.play("jump")
	animated_sprite.frame = frame_index
