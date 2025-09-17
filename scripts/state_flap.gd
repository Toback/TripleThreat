class_name FlapState extends State

@export var FLAP_HEIGHT := -30.0
@export var MAX_FLAP_HEIGHT := -100.0
@export var FLAP_HOVER_GRAVITY := 20.0
@export var FLAP_HOVER_TIMER := 0.15
@export var CEILING_FLAP_BOOST_TIMER := 0.2
@export var TIME_TO_EZ_HOVER := 1.0
@export var BUMPS_TO_EZ_HOVER := 3

@export var AIR_SPEED := 140.0 
@export var MAX_AIR_ACCELERATION := 1200.0
@export var MAX_AIR_DECELERATION := 300.0
@export var MAX_AIR_TURN_SPEED := 1200.0
@export var TERMINAL_DOWN_VELOCITY := 220.0
@export var TERMINAL_UP_VELOCITY := -180.0
@export var MAINTAIN_SCRAPE_RATE := 0.25 # 4 times a second

@export var JUMP_GRAVITY := 400.0
@export var FALL_GRAVITY := 1200.0
@export var SPEED_TO_MAX_GRAVITY := 500.0

@export var BUFFER_FLAP_TIMER := 0.13

# Scrape & Stick Constants
@export var STICK_TIMER := 0.2

@onready var ceiling_ray: RayCast2D = %CeilingRay


var flap_hover_timer: float = 0
var maintain_scrape_timer: float = 0
var stick_timer: float = STICK_TIMER
var flap_boost_timer: float = 0
var scrape_timer: float = 0.0
var scrape: bool = false
var sticking: bool = false
var current_gravity: float
var scrape_bumps: int

var buffer_flap: bool
var attempt_flap: bool
var attempt_buffer_flap: bool

var max_speed_change: float
var input_x: float
var input_hold_jump: bool
var input_pressed_jump: bool

var internal_velocity: Vector2
var just_touched_ceiling: bool = false
var just_touched_ceiling_timer: float
var velocity_before_touching_ceiling: float
var touching_ceiling: bool = false

func enter() -> void:
	print("flap")
	animated_sprite.play("jump")
	state_label.text = "flapping"
	internal_velocity = body.freeVelocity
	if attempt_flap:
		_flap()

	if attempt_buffer_flap:
		_buffer_flap()
	
func do(delta: float) -> void:
	maintain_scrape_timer = max(maintain_scrape_timer - delta, 0)
	stick_timer = max(stick_timer - delta, 0)
	flap_boost_timer = max(flap_boost_timer - delta, 0)
	flap_hover_timer = max(flap_hover_timer - delta, 0)
	scrape_timer = max(scrape_timer - delta, 0)
	just_touched_ceiling_timer = max(just_touched_ceiling_timer - delta, 0)
		
	if scrape and maintain_scrape_timer == 0:
		scrape_bumps = 0
		scrape = false
		
	if internal_velocity.y > 0:
		sticking = false
		
	input_x = input.get_movement_direction(body.PLAYER_ID).x
	input_hold_jump = input.wants_jump(body.PLAYER_ID)
	input_pressed_jump = input.wants_flap(body.PLAYER_ID)
	
	if(input_pressed_jump):
		if just_touched_ceiling_timer > 0:
			buffer_flap = true
		else:
			_flap()
	
	if buffer_flap and just_touched_ceiling_timer == 0:
		buffer_flap = false
		_buffer_flap()
	
	if body.grounded:
		is_complete = true
	return

func physics_do(delta: float) -> void:
	internal_velocity.y += gravity() * delta
	
	# Clamp player's fall & rise speeds	
	internal_velocity.y = min(internal_velocity.y, TERMINAL_DOWN_VELOCITY)
	internal_velocity.y = max(internal_velocity.y, TERMINAL_UP_VELOCITY)
	
	if input_x != 0:
		if(sign(input_x) != sign(internal_velocity.x) ):
			max_speed_change = MAX_AIR_TURN_SPEED * delta
		else:
			max_speed_change = MAX_AIR_ACCELERATION * delta
	else:
		max_speed_change = MAX_AIR_DECELERATION * delta
	
	var desired_velocity := input_x * AIR_SPEED
	internal_velocity.x = move_toward(internal_velocity.x, desired_velocity, max_speed_change)
	
	_check_if_just_touched_ceiling()
	_check_scrape_or_stick()

	body.freeVelocity = internal_velocity
	
	if scrape or sticking:
		body.freeVelocity.y = 0
	elif just_touched_ceiling:
		var bounce_vel = body.freeVelocity.bounce(Vector2.DOWN)
		body.freeVelocity = bounce_vel
		internal_velocity = bounce_vel
		
	just_touched_ceiling = false
	
func _check_if_just_touched_ceiling() -> void:
	# Need to include ceiling_ray because the y-jitters when we move which makes
	# the body not stay on the ceiling.
	if body.is_on_ceiling() and ceiling_ray.is_colliding() and !touching_ceiling:
		just_touched_ceiling = true
		just_touched_ceiling_timer = BUFFER_FLAP_TIMER
		velocity_before_touching_ceiling = body.velocity.y 
		touching_ceiling = true
		
		
	if !ceiling_ray.is_colliding():
		touching_ceiling = false
	
func exit() -> void:
	scrape_bumps = 0
	scrape = false
	just_touched_ceiling = false

func gravity() -> float:
	if scrape:
		return 0
	
	if just_touched_ceiling_timer > 0.0:
		if scrape or sticking:
			return FALL_GRAVITY
		else:
			return min(-(velocity_before_touching_ceiling * 10)  / max(scrape_bumps, BUMPS_TO_EZ_HOVER), FALL_GRAVITY)
	
	# If we're flapping, lower the gravity. Allows us to hover in mid-air
	# more easily
	if flap_hover_timer > 0.0:
		return FLAP_HOVER_GRAVITY
	
	# check if our character is going up. Godot has UP being negative y.
	if internal_velocity.y < 0.0 :
		# hold the jump button down to jump higher 
		if input_hold_jump:
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

func _flap() -> void:
	maintain_scrape_timer = MAINTAIN_SCRAPE_RATE
	# If you're sticking but not EZ Hovering then you're currently sticking
	# Therefore, if you flap while sticking you should come off the ceiling
	if sticking and not scrape:
		internal_velocity.y = TERMINAL_DOWN_VELOCITY
		return
	
	# Scale flap strength if character is falling
	# AKA, the faster you're falling the stronger you'll flap
	if internal_velocity.y > 0:  
		# If flapBoostTimer > 0 then we've hit a ceiling recenty. In order to help
		# establish an EZ HOVER, make it so that the flap strength is stronger
		if flap_boost_timer > 0:
			internal_velocity.y += FLAP_HEIGHT * 3.0
			internal_velocity.y = max(internal_velocity.y, FLAP_HEIGHT*3.0)
		else:
			# Scale factor based on how close character is to terminal velocity
			var factor = clamp(internal_velocity.y / TERMINAL_DOWN_VELOCITY, 0.0, 1.0)
			var extraFlapStrength = lerp(0.0, MAX_FLAP_HEIGHT - FLAP_HEIGHT, factor)
			internal_velocity.y += FLAP_HEIGHT + extraFlapStrength	
	else:
		internal_velocity.y += FLAP_HEIGHT
	
	flap_hover_timer = FLAP_HOVER_TIMER
	stick_timer = STICK_TIMER
	
func _buffer_flap() -> void:
	internal_velocity.y = FLAP_HEIGHT
	flap_hover_timer = FLAP_HOVER_TIMER
	stick_timer = STICK_TIMER
	
func _check_scrape_or_stick() -> void:
	### Handle sticking & ez hovering
	# If you're trying to move upward
	if internal_velocity.y < 0.0:
		# Check if we're hitting a downward-facing surface AKA a ceiling
		if body.is_on_ceiling():
			# We hit a ceiling, so reset the timer which allows us to EZ hover
			# TIME TO EZ HOVER is how long we have to hit a ceiling again in order
			# to establish our scrape.
			scrape_timer = TIME_TO_EZ_HOVER
			flap_boost_timer = CEILING_FLAP_BOOST_TIMER
			
			# We're moving up, hit a ceiling, and haven't tapped in stickTimer seconds
			# Therefore, allow ourselves to "stick", AKA start sticking on the ceiling
			if stick_timer == 0.0:
				sticking = true
			else:
				# We must've hit the while tapping too fast to stick. We'll now
				# Check for EZ Hover stuff
				#
				# EZ Hover only happens if you hit the ceiling BUMPS_TO_EZ_HOVER times
				# where each time you hit the ceiling falls within the TIME_TO_EZ_HOVER window.
				# So, increment the number of bumps if we do that 
				if scrape_timer > 0:
					scrape_bumps += 1
				# Then, if we've hit the ceiling BUMPS_TO_EZ_HOVER times, then begin ezhovering
				# and sticking
				if scrape_bumps > BUMPS_TO_EZ_HOVER:
					scrape = true
		else:
			scrape = false
			sticking = false
