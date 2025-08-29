extends CharacterBody2D

# drone
# Running (Left / Right) Constants
@export var RUN_SPEED = 180.0
@export var MAX_ACCELERATION = 900.0
@export var MAX_DECELERATION = 700.0
@export var MAX_TURN_SPEED = 3000.0
@export var MAX_AIR_ACCELERATION = 1200.0
@export var MAX_AIR_DECELERATION = 300.0
@export var MAX_AIR_TURN_SPEED = 1200.0

# Jumping (Up / Down) Constants
@export var JUMP_HEIGHT = 60.0
@export var JUMP_TIME_TO_PEAK = 0.4
@export var JUMP_TIME_TO_DESCENT = 0.22
@export var SPEED_TO_MAX_GRAVITY = 400.0
@export var TERMINAL_VELOCITY = 300.0
@export var COYOTO_TIME = 0.1
@export var JUMP_BUFFER = 0.1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: float
var maxSpeedChange: float
var desiredVelocity: Vector2
var jumpSpeed:   float 
var jumpGravity: float
var fallGravity: float
var currentGravity: float = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK    * JUMP_TIME_TO_PEAK))    * -1.0
var coyoteTimer: float
var jumpBufferTimer: float
var jumpCounter: int = 0

func gravity() -> float:
	# check if our character is going up. Godot has UP being negative y.
	if velocity.y < 0.0 :
		# hold the jump button down to jump higher 
		if Input.is_action_pressed("jump"):
			currentGravity = jumpGravity
			return currentGravity 
		# when you let go of the jump button while rising, you fall down at a faster fall gravity
		else:
			# Ease to the max fall gravity. Can set SPEED_TO_MAX_GRAVITY really high to just
			# go immediately to the fallGravity speed
			currentGravity = move_toward(currentGravity, fallGravity, SPEED_TO_MAX_GRAVITY)
			return currentGravity
	# once you start falling, fall down faster
	else:
		currentGravity = fallGravity
		return currentGravity

func _process(_delta: float) -> void:
	direction = Input.get_axis("move_left", "move_right")

	# How fast we can go once we we've hit our max speed
	desiredVelocity =  Vector2(direction, 0) * RUN_SPEED
	
func Jump() -> void:
	velocity.y = jumpSpeed
	# zero out timers, otherwise multiple jumps will register
	jumpBufferTimer = 0
	coyoteTimer = 0
	
func _physics_process(delta: float) -> void:	
	var onGround = is_on_floor()
	
	# Determine ON GROUND speeds / accelerations based on constants 
	var acceleration = MAX_ACCELERATION if onGround else MAX_AIR_ACCELERATION 
	var deceleration = MAX_DECELERATION if onGround else MAX_AIR_DECELERATION
	var turnSpeed    = MAX_TURN_SPEED   if onGround else MAX_AIR_TURN_SPEED
	
	# Determine ON JUMP speeds / accelerations based on constants
	# NOTE These don't rely on "onGround" so we can eventually move these to @onready varaibles
	# Currently done like this to allow us to experiment with different variables in editor   
	jumpSpeed   = (( 2.0 * JUMP_HEIGHT) /  JUMP_TIME_TO_PEAK)                            * -1.0
	jumpGravity = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK    * JUMP_TIME_TO_PEAK))    * -1.0
	fallGravity = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT)) * -1.0
	
	# If player is on the ground, max out their coyoteTimer so that once 
	# they get off the ground it starts counting down from the max
	if is_on_floor():
		coyoteTimer = COYOTO_TIME
	else:
		coyoteTimer = max(coyoteTimer - delta, 0)
	
	# Always count down jumpBufferTimer. We set this timer whenever we jump
	# when we're not allowed to.
	jumpBufferTimer = max(jumpBufferTimer - delta, 0)
	
	# Handle jump.
	# Check if we're allowed to jump by seeing if we're 
	# on the ground of recently left it
	if onGround || coyoteTimer > 0:
		# Jump if the button was pressed or we registered a jump recently
		if Input.is_action_just_pressed("jump") || jumpBufferTimer > 0: 
			Jump()
	# If we aren't allowed to jump, then set the jump buffer
	else:
		if Input.is_action_just_pressed("jump"):
			jumpBufferTimer = JUMP_BUFFER
	
	# Add the gravity.
	velocity.y += gravity() * delta
	
	# Clamp player's fall speed to the terminal velocity	
	velocity.y = min(velocity.y, TERMINAL_VELOCITY)
	
	# If we're moving left or right
	if direction != 0:
		# If we're trying to move in a different direction 
		# than we're going then we must be turning, so apply turn speed
		if(sign(direction) != sign(velocity.x) ):
			maxSpeedChange = turnSpeed * delta
		# otherwise, we're holding in the direction we're moving, so accelerate
		else:
			maxSpeedChange = acceleration * delta
	# If we're not moving left or right, then we're decelerating.
	else:
		maxSpeedChange = deceleration * delta
		
	# flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	# Simple animations
	if onGround:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
		
	velocity.x = move_toward(velocity.x, desiredVelocity.x, maxSpeedChange)
	
	move_and_slide()

func transformIntoWarrior():
	# Instantiate a warrior
	var warrior = preload("res://scenes/warrior.tscn").instantiate()
	
	# Set warriors position and velocity this the drone's 
	warrior.global_position = global_position
	warrior.velocity = velocity  # optional if your new script uses velocity
	
	# Add the warrior to the game world
	get_parent().add_child(warrior)
	
	# Remove drone
	queue_free()
