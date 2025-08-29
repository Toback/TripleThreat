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
@export var FALL_GRAVITY := 1200.0
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
@export_range(0.0, 1.0, 0.05) var CEILING_BOUNCINESS: float = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ceilingRayCast: RayCast2D = $RayCast2D

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


var scrapeBumps: int = 0
var scrapeTimer: float = 0.0
var flapBoostTimer: float = 0.0

func gravity() -> float:
	# If we're flapping, lower the gravity. Allows us to hover in mid-air
	# more easily
	if flapHoverTimer > 0.0:
		return FLAP_HOVER_GRAVITY
	
	# check if our character is going up. Godot has UP being negative y.
	if freeVelocity.y < 0.0 :
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
	if is_on_floor():
		desiredVelocity =  Vector2(direction, 0) * RUN_SPEED
		if jumping:
			jumping = false
	else:
		#desiredVelocity = Vector2(move_toward(velocity.x, direction * AIR_SPEED, 1), 0)
		desiredVelocity =  Vector2(direction, 0) * AIR_SPEED
		
func Jump() -> void:
	
	freeVelocity.y = jumpSpeed
	# zero out timers, otherwise multiple jumps will register
	jumpBufferTimer = 0
	coyoteTimer = 0
	jumping = true

func Flap() -> void:
	# If you're scraping but not EZ Hovering then you're currently sticking
	# Therefore, if you flap while sticking you should come off the ceiling
	if scraping and not ezHover:
		freeVelocity.y = TERMINAL_DOWN_VELOCITY
		return
	
	
	# Scale flap strength if character is falling
	# AKA, the faster you're falling the stronger you'll flap
	if freeVelocity.y > 0:  
		# Scale factor based on how close character is to terminal velocity
		var factor = clamp(freeVelocity.y / TERMINAL_DOWN_VELOCITY, 0.0, 1.0)
		var extraFlapStrength = lerp(0.0, MAX_FLAP_HEIGHT - FLAP_HEIGHT, factor)
		freeVelocity.y += FLAP_HEIGHT + extraFlapStrength	
	else:
		freeVelocity.y += FLAP_HEIGHT
	
	# If flapBoostTimer > 0 then we've hit a ceiling recenty. In order to help
	# establish an EZ HOVER, make it so that the flap strength is stronger
	if flapBoostTimer > 0:
		#print("assist ", flapBoostTimer)
		freeVelocity.y += FLAP_HEIGHT * 2.0
		freeVelocity.y = max(freeVelocity.y, FLAP_HEIGHT*2.0)

	flapHoverTimer = FLAP_HOVER_TIMER
	# zero out timers, otherwise multiple jumps will register
	jumpBufferTimer = 0
	coyoteTimer = 0
	stickTimer = STICK_TIMER
	jumping = false
	
func _physics_process(delta: float) -> void:	
	#print("HELLO ", velocity.y)
	var onGround = is_on_floor()
	
	### Determine ON GROUND speeds / accelerations based on constants 
	var acceleration = MAX_ACCELERATION if onGround else MAX_AIR_ACCELERATION 
	var deceleration = MAX_DECELERATION if onGround else MAX_AIR_DECELERATION
	var turnSpeed    = MAX_TURN_SPEED   if onGround else MAX_AIR_TURN_SPEED
	
	### Determine ON JUMP speeds / accelerations based on constants
	# NOTE These don't rely on "onGround" so we can eventually move these to @onready varaibles
	# Currently done like this to allow us to experiment with different variables in editor   
	#jumpSpeed   = (( 2.0 * JUMP_HEIGHT) /  JUMP_TIME_TO_PEAK)                            * -1.0
	#jumpGravity = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_PEAK    * JUMP_TIME_TO_PEAK))    * -1.0
	#fallGravity = ((-2.0 * JUMP_HEIGHT) / (JUMP_TIME_TO_DESCENT * JUMP_TIME_TO_DESCENT)) * -1.0
	jumpSpeed = JUMP_SPEED
	jumpGravity = JUMP_GRAVITY
	fallGravity = FALL_GRAVITY
	
	# If we're moving up or down then we're not scraping or ez hovering
	if freeVelocity.y != 0.0:
		scraping = false
		ezHover = false
	
	
	### Handle timers
	if onGround:
		coyoteTimer = COYOTO_TIME
	else:
		coyoteTimer = max(coyoteTimer - delta, 0)
	# Always count down following timers. We set this timer whenever we jump
	# when we're not allowed to.
	jumpBufferTimer = max(jumpBufferTimer - delta, 0)
	flapHoverTimer = max(flapHoverTimer - delta, 0.0)
	stickTimer = max(stickTimer - delta, 0)
	scrapeTimer = max(scrapeTimer - delta, 0)
	flapBoostTimer = max(flapBoostTimer - delta, 0) 
	if scrapeTimer == 0:
		scrapeBumps = 0
	
	# Add the gravity (to free velocity, not actual movement yet)
	freeVelocity.y += gravity() * delta
	
	# Clamp player's fall & rise speeds	
	freeVelocity.y = min(freeVelocity.y, TERMINAL_DOWN_VELOCITY)
	if not jumping:
		freeVelocity.y = max(freeVelocity.y, TERMINAL_UP_VELOCITY)
	
	# Horizontal acceleration applied to freeVelocity.x
	if direction != 0:
		if(sign(direction) != sign(freeVelocity.x) ):
			maxSpeedChange = turnSpeed * delta
		else:
			maxSpeedChange = acceleration * delta
	else:
		maxSpeedChange = deceleration * delta
	
	freeVelocity.x = move_toward(freeVelocity.x, desiredVelocity.x, maxSpeedChange)
	
	### flip sprite
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
	
	### Handle Scraping & Sticking
	# If you're trying to move upward
	if freeVelocity.y < 0.0:
		# Check if we're hitting a downward-facing surface AKA a ceiling
		if is_on_ceiling():
			# We hit a ceiling, so reset the timer which allows us to EZ hover
			# TIME TO EZ HOVER is how long we have to hit a ceiling again in order
			# to establish our scrape.
			scrapeTimer = TIME_TO_EZ_HOVER
			flapBoostTimer = CEILING_FLAP_BOOST_TIMER
			
			# We're moving up, hit a ceiling, and haven't tapped in stickTimer seconds
			# Therefore, allow ourselves to "stick", AKA start scraping on the ceiling
			if stickTimer == 0.0:
				scraping = true
			else:
				# We must've hit the while tapping too fast to stick. We'll now
				# Check for EZ Hover stuff
				#
				# EZ Hover only happens if you hit the ceiling BUMPS_TO_EZ_HOVER times
				# where each time you hit the ceiling falls within the TIME_TO_EZ_HOVER window.
				# So, increment the number of bumps if we do that 
				if scrapeTimer > 0:
					scrapeBumps += 1
				# Then, if we've hit the ceiling BUMPS_TO_EZ_HOVER times, then begin ezhovering
				# and scraping
				if scrapeBumps > BUMPS_TO_EZ_HOVER:
					scraping = true
					ezHover = true
				
	### Handle jump and flapping
	# Check if we're allowed to jump by seeing if we're 
	# on the ground of recently left it
	if onGround || coyoteTimer > 0:
		# Jump if the button was pressed or we registered a jump recently
		if Input.is_action_just_pressed("jump") || jumpBufferTimer > 0: 
			Jump()
	# If we aren't allowed to jump, then fly
	else:
		if Input.is_action_just_pressed("jump"):
			Flap()
	
	velocity = freeVelocity
	
	# If we hit the ceiling then, if we're scraping, don't move upward
	# If we aren't scraping, then bounce off the ceiling with you current
	# upwards desired velocity multiplied by the CEILING_BOUNCINESS of the
	# ceiling
	if is_on_ceiling():
		if scraping:
			velocity.y = 0 
		else:
			freeVelocity.y = abs(freeVelocity.y) * CEILING_BOUNCINESS
			velocity.y = freeVelocity.y
			
	
				
	move_and_slide()
