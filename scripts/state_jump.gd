class_name JumpState extends State

var jumping: bool
var jump_speed: float
var input_x: float
var input_jump: bool
var current_gravity: float
var max_speed_change: float
var attempt_jump: bool
var jump_from_wall: bool

var wall_jump_timer: float
var wall_jump_dir: int

@export var JUMP_SPEED := -250.0
@export var JUMP_GRAVITY := 400.0
@export var FALL_GRAVITY := 2000.0
@export var SPEED_TO_MAX_GRAVITY := 500.0

@export var MAX_AIR_ACCELERATION := 1200.0
@export var MAX_AIR_DECELERATION := 300.0
@export var MAX_AIR_TOO_FAST_DECELERATION := 600.0
@export var MAX_AIR_TURN_SPEED := 1200.0
@export var AIR_SPEED := 140.0 

@export var WALL_JUMP_TIME := 0.2

@export var TERMINAL_DOWN_VELOCITY := 260.0

func enter() -> void:
	print("jump")
	animated_sprite.play("jump")
	state_label.text = "jump"
	jumping = true
	if (body.left_wall_cling_ray.is_colliding() || body.right_wall_cling_ray.is_colliding()) and !body.grounded: 
		jump_from_wall = true
	if attempt_jump:
		body.grounded = false
		if jump_from_wall:
			_wall_jump()
		else:
			_jump()
	
func do(delta: float) -> void:	
	_handle_animation()
	input_x = input.get_movement_direction(body.PLAYER_ID).x
	input_jump = input.wants_hold_jump(body.PLAYER_ID)
	wall_jump_timer = max(wall_jump_timer - delta, 0)
	if body.grounded or (!body.grounded and !jumping):
		is_complete = true

func physics_do(delta: float) -> void:
	body.freeVelocity.y += gravity() * delta
	
	# Clamp player's fall
	body.freeVelocity.y = min(body.freeVelocity.y, TERMINAL_DOWN_VELOCITY)
	
	if wall_jump_timer > 0:
		body.freeVelocity.x = move_toward(body.freeVelocity.x, wall_jump_dir * AIR_SPEED, MAX_AIR_ACCELERATION * delta)
	else:
		if input_x != 0:
			if(sign(input_x) != sign(body.freeVelocity.x) ):
				max_speed_change = MAX_AIR_TURN_SPEED * delta
			else:
				# Normal acceleration
				if abs(body.velocity.x) <= AIR_SPEED:
					max_speed_change = MAX_AIR_ACCELERATION * delta
				# We're moving faster than AIR_SPEED, so we're actually decelerating
				else:
					max_speed_change = MAX_AIR_TOO_FAST_DECELERATION * delta
		else:
			max_speed_change = MAX_AIR_DECELERATION * delta
		
		var desired_velocity_x: float = input_x * AIR_SPEED 
		# Handle slowing down from our super fast speed. Want to ease into it slowly.
		if input_x > 0 and body.velocity.x >= AIR_SPEED:
			body.freeVelocity.x = move_toward(body.freeVelocity.x, AIR_SPEED, max_speed_change)
		elif input_x < 0 and body.velocity.x <= -AIR_SPEED:
			body.freeVelocity.x = move_toward(body.freeVelocity.x, -AIR_SPEED, max_speed_change)
		else:
			body.freeVelocity.x = move_toward(body.freeVelocity.x, desired_velocity_x, max_speed_change)

func _jump() -> void:
	body.freeVelocity.y = JUMP_SPEED

func _wall_jump() -> void:
	wall_jump_timer = WALL_JUMP_TIME
	wall_jump_dir = -input.wall_colliding(body)
	body.freeVelocity.y = JUMP_SPEED
	body.freeVelocity.x = wall_jump_dir * AIR_SPEED

func exit() -> void:
	jumping = false
	jump_from_wall = false
	wall_jump_timer = 0
	
	
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
			
func _handle_animation() -> void:
	var anim_time: float = Helpers.map(body.velocity.y, jump_speed, -jump_speed, 0, 1, true)
	var total_frames: int = animated_sprite.sprite_frames.get_frame_count("jump")
	var frame_index = int(anim_time * (total_frames - 1))
	animated_sprite.play("jump")
	animated_sprite.frame = frame_index
