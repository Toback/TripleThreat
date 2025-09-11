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

# Scrape & Stick Constants
@export var STICK_TIMER := 0.2

var flap_hover_timer: float = 0
var jumpBufferTimer: float = 0
var maintain_scrape_timer: float = 0
var coyoteTimer: float = 0
var stickTimer: float = STICK_TIMER
var flapBoostTimer: float = 0
var scrapeTimer: float = 0.0
var ezHover: bool = false
var desired_velocity: float
var current_gravity: float

var attempt_flap: bool
var attempt_buffer_flap: bool

var max_speed_change: float
var input_x: float
var input_hold_jump: bool
var input_pressed_jump: bool

func enter() -> void:
	print("flap")
	animated_sprite.play("jump")
	state_label.text = "flapping"
	if attempt_flap:
		_flap()

	if attempt_buffer_flap:
		_buffer_flap()
	
func do(delta: float) -> void:
	#print("flapping")
	#if grounded or dash_timer > 0 or bounce_timer > 0:
	# if input then flap()	
	
	#if input.wants_jump():
		#body.ezHoverTimer = body.EZ_HOVER_MAINTAIN_RATE
		#if justTouchedCeilingTimer > 0 and not ezHover:
			#bufferFlap = true
		#else:
			#Flap()
	#body.freeVelocity.y += gravity() * delta
	maintain_scrape_timer = max(maintain_scrape_timer - delta, 0)
	input_x = input.get_movement_direction().x
	input_hold_jump = input.wants_jump()
	input_pressed_jump = input.wants_flap()
	
	flap_hover_timer = max(flap_hover_timer - delta, 0)
	if(input_pressed_jump):
		_flap()
	#desired_velocity = Vector2(input.get_movement_direction().x, 0) * AIR_SPEED
	if body.grounded:
		is_complete = true
	return

func fixed_do(delta: float) -> void:
	#var max_speed_change
	#var input_x = input.get_movement_direction().x
	
	body.freeVelocity.y += gravity() * delta
	
	# Clamp player's fall & rise speeds	
	body.freeVelocity.y = min(body.freeVelocity.y, TERMINAL_DOWN_VELOCITY)
	body.freeVelocity.y = max(body.freeVelocity.y, TERMINAL_UP_VELOCITY)
	
	if input_x != 0:
		if(sign(input_x) != sign(body.freeVelocity.x) ):
			max_speed_change = MAX_AIR_TURN_SPEED * delta
		else:
			max_speed_change = MAX_AIR_ACCELERATION * delta
	else:
		max_speed_change = MAX_AIR_DECELERATION * delta
	
	desired_velocity = input_x * AIR_SPEED
	body.freeVelocity.x = move_toward(body.freeVelocity.x, desired_velocity, max_speed_change)

func exit() -> void:
	push_warning("_exit not implemented")

func gravity() -> float:
	if body.justTouchedCeilingTimer > 0.0:
		if body.ezHover or body.sticking:
			return FALL_GRAVITY
		else:
			return min(-(body.velocityBeforeTouchingCeiling *10)  /max(body.scrapeBumps, body.BUMPS_TO_EZ_HOVER), FALL_GRAVITY)
	
	# If we're flapping, lower the gravity. Allows us to hover in mid-air
	# more easily
	if flap_hover_timer > 0.0:
		return FLAP_HOVER_GRAVITY
	
	# check if our character is going up. Godot has UP being negative y.
	if body.freeVelocity.y < 0.0 :
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
	if body.sticking and not body.ezHover:
		body.freeVelocity.y = body.TERMINAL_DOWN_VELOCITY
		return
	
	# Scale flap strength if character is falling
	# AKA, the faster you're falling the stronger you'll flap
	if body.freeVelocity.y > 0:  
		# If flapBoostTimer > 0 then we've hit a ceiling recenty. In order to help
		# establish an EZ HOVER, make it so that the flap strength is stronger
		if flapBoostTimer > 0:
			body.freeVelocity.y += FLAP_HEIGHT * 3.0
			body.freeVelocity.y = max(body.freeVelocity.y, FLAP_HEIGHT*3.0)
		else:
			# Scale factor based on how close character is to terminal velocity
			var factor = clamp(body.freeVelocity.y / body.TERMINAL_DOWN_VELOCITY, 0.0, 1.0)
			var extraFlapStrength = lerp(0.0, MAX_FLAP_HEIGHT - FLAP_HEIGHT, factor)
			body.freeVelocity.y += FLAP_HEIGHT + extraFlapStrength	
	else:
		body.freeVelocity.y += FLAP_HEIGHT
	
	# zero out timers, otherwise multiple jumps will register
	flap_hover_timer = FLAP_HOVER_TIMER
	#jumpBufferTimer = 0
	#coyoteTimer = 0
	stickTimer = STICK_TIMER
	
func _buffer_flap() -> void:
	body.freeVelocity.y = FLAP_HEIGHT
	
	# Record the jump time
	#var now = Time.get_ticks_msec     ()  / 1000.0
	#jumpTimes.append(now)

	# zero out timers, otherwise multiple jumps will register
	flap_hover_timer = FLAP_HOVER_TIMER
	jumpBufferTimer = 0
	coyoteTimer = 0
	stickTimer = STICK_TIMER
	#jump_state.jumping = false
	
#func HandleStickAndEZHover() -> void:
	#### Handle sticking & ez hovering
	## If you're trying to move upward
	#if body.freeVelocity.y < 0.0:
		## Check if we're hitting a downward-facing surface AKA a ceiling
		#if body.grounded:
			## We hit a ceiling, so reset the timer which allows us to EZ hover
			## TIME TO EZ HOVER is how long we have to hit a ceiling again in order
			## to establish our scrape.
			#scrapeTimer = TIME_TO_EZ_HOVER
			#flapBoostTimer = CEILING_FLAP_BOOST_TIMER
			#
			## We're moving up, hit a ceiling, and haven't tapped in stickTimer seconds
			## Therefore, allow ourselves to "stick", AKA start sticking on the ceiling
			#if stickTimer == 0.0:
				#body.sticking = true
			#else:
				## We must've hit the while tapping too fast to stick. We'll now
				## Check for EZ Hover stuff
				##
				## EZ Hover only happens if you hit the ceiling BUMPS_TO_EZ_HOVER times
				## where each time you hit the ceiling falls within the TIME_TO_EZ_HOVER window.
				## So, increment the number of bumps if we do that 
				#if scrapeTimer > 0:
					#body.scrapeBumps += 1
				## Then, if we've hit the ceiling BUMPS_TO_EZ_HOVER times, then begin ezhovering
				## and sticking
				#if body.scrapeBumps > BUMPS_TO_EZ_HOVER:
					#ezHover = true
					#bufferFlap = false
