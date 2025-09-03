extends CharacterBody2D

# Running (Left / Right) Constants
@export var RUN_SPEED := 180.0 
@export var MAX_ACCELERATION := 900.0
@export var MAX_DECELERATION := 700.0
@export var MAX_TURN_SPEED := 3000.0
@export var AIR_SPEED := 140.0 
@export var MAX_AIR_ACCELERATION := 1200.0
@export var MAX_AIR_DECELERATION := 300.0
@export var MAX_AIR_TURN_SPEED := 1200.0

# Jumping (Up / Down) Constants
@export var JUMP_SPEED := -270.0
@export var JUMP_GRAVITY := 400.0
@export var FALL_GRAVITY := 100.0
@export var SPEED_TO_MAX_GRAVITY := 500.0
@export var TERMINAL_DOWN_VELOCITY := 220.0
@export var TERMINAL_UP_VELOCITY := -180.0
@export var COYOTO_TIME := 0.05
@export var JUMP_BUFFER := 0.1

# Flying Constants
@export var FLAP_HEIGHT := -30.0
@export var MAX_FLAP_HEIGHT := -100.0
@export var FLAP_HOVER_GRAVITY := 20.0
@export var FLAP_HOVER_TIMER := 0.15

# Scrape & Stick Constants
@export var STICK_TIMER := 0.2
@export var BUMPS_TO_EZ_HOVER := 3
@export var TIME_TO_EZ_HOVER := 0.4
@export var CEILING_FLAP_BOOST_TIMER := 0.2
@export_range(0.0, 1.0, 0.05) var CEILING_BOUNCINESS: float = 0.5
@export var BOUNCE_THRESHOLD := -120.0
@export var SCRAPE_THRESHOLD := -40.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ceilingRayCast: RayCast2D = $RayCast2D
@onready var timer: Timer = %Timer

var direction: float
var maxSpeedChange: float
var desiredVelocity: Vector2
var jumpSpeed:   float 
var jumpGravity: float
var fallGravity: float
var flapSpeed:    float 
var currentGravity: float = JUMP_GRAVITY
var coyoteTimer: float
var jumpBufferTimer: float
var flapHoverTimer: float
var stickTimer: float
var jumpCounter: int = 0
var scraping: bool = false
var ezHover: bool = false
var freeVelocity: Vector2 = Vector2.ZERO
var jumpedOnLatch: bool = false
var jumping: bool = false
var jump_times: Array = []

var timeSinceCeiling: float

var scrapeBumps: int = 0
var scrapeTimer: float = 0.0
var flapBoostTimer: float = 0.0

var counter: int = 0
var debugBool: bool = false
var justTouchedCeilingTimer: float = 0
var timeOfLastFlap: float = Time.get_ticks_msec()  / 1000.0
var bufferFlap: bool = false
var attemptedFlap: bool = false

func _ready() -> void:
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	#print("TICK at: ", Time.get_ticks_msec() / 1000.0)
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = true
	Input.parse_input_event(ev)

	# Optionally also simulate "release" right away (tap behavior):
	var ev_release := InputEventAction.new()
	ev_release.action = "jump"
	ev_release.pressed = false
	Input.parse_input_event(ev_release)

func gravity() -> float:
	## If we're flapping, lower the gravity. Allows us to hover in mid-air
	## more easily
	#if flapHoverTimer > 0.0:
		#return FLAP_HOVER_GRAVITY
	#
	## check if our character is going up. Godot has UP being negative y.
	#if freeVelocity.y < 0.0 :
		## hold the jump button down to jump higher 
		#if Input.is_action_pressed("jump"):
			#currentGravity = jumpGravity
			#return currentGravity 
		## when you let go of the jump button while rising, you fall down at a faster fall gravity
		#else:
			## Ease to the max fall gravity. Can set SPEED_TO_MAX_GRAVITY really high to just
			## go immediately to the fallGravity speed
			#currentGravity = move_toward(currentGravity, fallGravity, SPEED_TO_MAX_GRAVITY)
			#return currentGravity
	## once you start falling, fall down faster
	#else:
		#currentGravity = fallGravity
		#return currentGravity
	return fallGravity

func _process(_delta: float) -> void:
	var now = Time.get_ticks_msec()  / 1000.0
	direction = Input.get_axis("move_left", "move_right")
	### Handle jump and flapping
	# Check if we're allowed to jump by seeing if we're 
	# on the ground of recently left it
	if is_on_floor() || coyoteTimer > 0:
		# Jump if the button was pressed or we registered a jump recently
		if Input.is_action_just_pressed("jump") || jumpBufferTimer > 0: 
			Jump()
	# If we aren't allowed to jump, then fly
	else:
		if Input.is_action_just_pressed("jump"):
			# If it's been over 0.1 seconds since we last tapped, then flap and record when it happened/
			# Otherwise, buffer the flap to occur later
			if now - timeOfLastFlap > 0.1 and justTouchedCeilingTimer == 0:
				Flap()
				timeOfLastFlap = Time.get_ticks_msec()  / 1000.0
				
			else:
				#if justTouchedCeilingTimer > 0:
					#print("buffering ceiling")
					#print("velocity y ", velocity.y)
				bufferFlap = true

	# Flap if we have one buffered and it's been enough time. Notice this happens
	# without having to press a button, it's only because it's buffered.
	if bufferFlap and now - timeOfLastFlap > 0.1 and justTouchedCeilingTimer == 0:
		print("buffered flap")
		print("velocity y ", freeVelocity.y)
		bufferFlap = false
		Flap()	
		#timeOfLastFlap = Time.get_ticks_msec()  / 1000.0
	
	
		

	# How fast we can go once we we've hit our max speed
	if is_on_floor():
		desiredVelocity =  Vector2(direction, 0) * RUN_SPEED
		if jumping:
			jumping = false
	else:
		desiredVelocity =  Vector2(direction, 0) * AIR_SPEED
		
func jumpsPerSecond() -> float:
	var now = Time.get_ticks_msec()  / 1000.0
	var window = 1.0  # 1-second rolling window
	
	# Remove jumps older than the window
	jump_times = jump_times.filter(func(t): return t >= now - window)

	var duration = max(jump_times[-1] - jump_times[0], 0.2)
	if duration <= 0.0:
		return 0.0  # Prevent division by zero
	
	# Jumps per second
	return float(jump_times.size()) / duration

func Jump() -> void:
	
	freeVelocity.y = jumpSpeed
	# zero out timers, otherwise multiple jumps will register
	jumpBufferTimer = 0
	coyoteTimer = 0
	jumping = true

func Flap() -> void:
	#if justTouchedCeiling:
		#print("Time from ceiling bounce to flap ", (Time.get_ticks_msec()  / 1000.0) -  timeSinceCeiling )
		#justTouchedCeiling = false
	#if velocity.y > 0 :
		#print("flap")
	# If you're scraping but not EZ Hovering then you're currently sticking
	# Therefore, if you flap while sticking you should come off the ceiling
	if scraping and not ezHover:
		freeVelocity.y = TERMINAL_DOWN_VELOCITY
		return
	
	
	# Scale flap strength if character is falling
	# AKA, the faster you're falling the stronger you'll flap
	
	#NOTE undo these comments
	#if freeVelocity.y > 0:  
		## If flapBoostTimer > 0 then we've hit a ceiling recenty. In order to help
		## establish an EZ HOVER, make it so that the flap strength is stronger
		#if flapBoostTimer > 0:
			#
			#freeVelocity.y += FLAP_HEIGHT * 3.0
			#freeVelocity.y = max(freeVelocity.y, FLAP_HEIGHT*3.0)
		#else:
			## Scale factor based on how close character is to terminal velocity
			#var factor = clamp(freeVelocity.y / TERMINAL_DOWN_VELOCITY, 0.0, 1.0)
			#var extraFlapStrength = lerp(0.0, MAX_FLAP_HEIGHT - FLAP_HEIGHT, factor)
			#freeVelocity.y += FLAP_HEIGHT + extraFlapStrength	
	#else:
	freeVelocity.y += FLAP_HEIGHT
	# Record the jump time

	var now = Time.get_ticks_msec()  / 1000.0
	jump_times.append(now)
	#print("Jumps per second: ", jumpsPerSecond())

	flapHoverTimer = FLAP_HOVER_TIMER
	# zero out timers, otherwise multiple jumps will register
	jumpBufferTimer = 0
	coyoteTimer = 0
	stickTimer = STICK_TIMER
	jumping = false
	
func _physics_process(delta: float) -> void:
	var onGround = is_on_floor()

	### Determine ON GROUND speeds / accelerations
	var acceleration = MAX_ACCELERATION if onGround else MAX_AIR_ACCELERATION 
	var deceleration = MAX_DECELERATION if onGround else MAX_AIR_DECELERATION
	var turnSpeed    = MAX_TURN_SPEED   if onGround else MAX_AIR_TURN_SPEED
	
	# Jump / gravity setup
	jumpSpeed = JUMP_SPEED
	jumpGravity = JUMP_GRAVITY
	fallGravity = 40
	
	# If we're moving vertically, we’re not scraping
	if freeVelocity.y != 0.0:
		scraping = false
		ezHover = false
	
	### Handle timers
	if onGround:
		coyoteTimer = COYOTO_TIME
	else:
		coyoteTimer = max(coyoteTimer - delta, 0)

	jumpBufferTimer = max(jumpBufferTimer - delta, 0)
	flapHoverTimer = max(flapHoverTimer - delta, 0.0)
	stickTimer = max(stickTimer - delta, 0)
	scrapeTimer = max(scrapeTimer - delta, 0)
	flapBoostTimer = max(flapBoostTimer - delta, 0)
	justTouchedCeilingTimer = max(justTouchedCeilingTimer - delta, 0) 
	if scrapeTimer == 0:
		scrapeBumps = 0
	
	# Apply gravity
	freeVelocity.y += gravity() * delta

	# Clamp vertical speeds
	freeVelocity.y = min(freeVelocity.y, TERMINAL_DOWN_VELOCITY)
	if not jumping:
		freeVelocity.y = max(freeVelocity.y, TERMINAL_UP_VELOCITY)

	# Horizontal accel
	if direction != 0:
		if sign(direction) != sign(freeVelocity.x):
			maxSpeedChange = turnSpeed * delta
		else:
			maxSpeedChange = acceleration * delta
	else:
		maxSpeedChange = deceleration * delta

	freeVelocity.x = move_toward(freeVelocity.x, desiredVelocity.x, maxSpeedChange)

	### Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	### Simple animations
	if onGround:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	### Movement with move_and_collide
	var motion = freeVelocity * delta
	var collision = move_and_collide(motion)

	if collision:
		var n = collision.get_normal()

		# Ceiling hit
		if n.y > 0:
			freeVelocity.y = 50
				#if freeVelocity.y < 50:  # make sure bounce isn't too weak
					#freeVelocity.y = 50
