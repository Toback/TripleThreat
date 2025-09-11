extends CharacterBody2D

@export var PLAYER_ID := 0 

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
@export var JUMP_SPEED := -250.0
@export var JUMP_GRAVITY := 400.0
@export var FALL_GRAVITY := 1200.0
@export var SPEED_TO_MAX_GRAVITY := 500.0
@export var TERMINAL_DOWN_VELOCITY := 220.0
@export var TERMINAL_UP_VELOCITY := -180.0
@export var COYOTO_TIME := 0.05
@export var JUMP_BUFFER := 0.1

# Dashing Constants
@export var DASH_SPEED := 400.0
@export var DASH_TIME := 0.1

# Bounce Constants
@export var BOUNCE_TIME := 0.5

# Flying Constants
@export var FLAP_HEIGHT := -30.0
@export var MAX_FLAP_HEIGHT := -100.0
@export var FLAP_HOVER_GRAVITY := 20.0
@export var FLAP_HOVER_TIMER := 0.15

# Scrape & Stick Constants
@export var STICK_TIMER := 0.2
@export var BUMPS_TO_EZ_HOVER := 3
@export var TIME_TO_EZ_HOVER := 1.0
#@export var EZ_HOVER_MAINTAIN_RATE := 0.25 # 4 times a second
@export var CEILING_FLAP_BOOST_TIMER := 0.2
@export_range(0.0, 3.0, 0.05) var CEILING_BOUNCINESS: float = 1.1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ceilingRayCast: RayCast2D = $CeilingRay
@onready var timer: Timer = %Timer
@onready var jRayCast: RayCast2D = $JRay
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var platform_collider: CollisionShape2D = $PlatformCollider
@onready var hitBox: Area2D = $HitBox
@onready var state_label: Label = $StateLabel


var direction: float
var maxSpeedChange: float
var desiredVelocity: Vector2
#var jumpSpeed:   float 
var jumpGravity: float
var fallGravity: float
var flapSpeed:    float 
var currentGravity: float = JUMP_GRAVITY
var coyote_timer: float
var jump_buffer_timer: float
var flapHoverTimer: float
#var ezHoverTimer: float
var stickTimer: float
#var dashDir: Vector2 = Vector2.ZERO
var sticking: bool = false
var ezHover: bool = false
var freeVelocity: Vector2 = Vector2.ZERO
#var jumping: bool = false
var jumpTimes: Array = []
var deathCounter: int = 0
var physicsFrame: int = 0

var scrapeBumps: int = 0
var scrapeTimer: float = 0.0
var flapBoostTimer: float = 0.0

var justTouchedCeilingTimer: float = 0
var justTouchedCeilingBool: bool = false
var velocityBeforeTouchingCeiling: = 0.0
var bufferFlap: bool = false
#var canDash: bool = true
var hasDashed: bool = false
var isInteractable: bool = true

#var bounceSpeedX: float = 0.0
#var bounceSpeedY: float = 0.0
var bounceSpeed: Vector2 = Vector2.ZERO
			
			
## NOTE 
# state machine updates
#enum player_state {idle, running, jumping, flapping, dashing, bouncing}


var state: State
@onready var bounce_state = $states/bounce_state as BounceState
@onready var dash_state   = $states/dash_state   as DashState
@onready var flap_state   = $states/flap_state   as FlapState
@onready var idle_state   = $states/idle_state   as IdleState
@onready var jump_state   = $states/jump_state   as JumpState
@onready var run_state    = $states/run_state    as RunState

@onready var player_input = $input_component     as InputComponent

var input_dir: Vector2
var input_jump: bool
var input_dash: bool
var grounded: bool = false
	
func _ready() -> void:
	bounce_state.setup(self, animated_sprite, player_input, state_label)
	dash_state.setup(self, animated_sprite, player_input, state_label)
	flap_state.setup(self, animated_sprite, player_input, state_label)
	idle_state.setup(self, animated_sprite, player_input, state_label)
	jump_state.setup(self, animated_sprite, player_input, state_label)
	run_state.setup(self, animated_sprite, player_input, state_label)
	state = idle_state

func tryingToJ():
	if jRayCast.is_colliding() and not ceilingRayCast.is_colliding():
		return true
	return false
		
func gravity() -> float:
	#if state == dash_state:
		#return 0
	
	if justTouchedCeilingTimer > 0.0:
		if ezHover or sticking:
			return fallGravity
		else:
			return min(-(velocityBeforeTouchingCeiling *10)  /max(scrapeBumps, BUMPS_TO_EZ_HOVER), fallGravity)

	# If we're flapping, lower the gravity. Allows us to hover in mid-air
	# more easily
	if flapHoverTimer > 0.0:
		return FLAP_HOVER_GRAVITY
	
	# check if our character is going up. Godot has UP being negative y.
	if freeVelocity.y < 0.0 :
		# hold the jump button down to jump higher 
		if input_jump:
			currentGravity = jumpGravity
			return currentGravity 
			# when you let go of the jump button while rising, you fall down at a faster fall gravity
		else:
			# Ease to the max fall gravity. Can set SPEED_TO_MAX_GRAVITY really high to just
			# go immediately to the fallGravity speed
			currentGravity = move_toward(currentGravity, fallGravity, SPEED_TO_MAX_GRAVITY)
			#currentGravity = fallGravity
			return currentGravity
	# once you start falling, fall down faster
	else:
		currentGravity = fallGravity
		return currentGravity

#func Jump() -> void:
	#freeVelocity.y = JUMP_SPEED
	## zero out timers, otherwise multiple jumps will register
	#jumpBufferTimer = 0
	#coyoteTimer = 0
	#jump_state.jumping = true


	
func Dash() -> void:
	dash_state.dash_timer = DASH_TIME
	#dashDir = Helpers.get_snapped_direction(inputDir)	
	#canDash = false
	hasDashed = true
	#jump_state.jumping = false

func Flap() -> void:
	# If you're sticking but not EZ Hovering then you're currently sticking
	# Therefore, if you flap while sticking you should come off the ceiling
	if sticking and not ezHover:
		freeVelocity.y = TERMINAL_DOWN_VELOCITY
		return
	
	# Scale flap strength if character is falling
	# AKA, the faster you're falling the stronger you'll flap
	if freeVelocity.y > 0:  
		# If flapBoostTimer > 0 then we've hit a ceiling recenty. In order to help
		# establish an EZ HOVER, make it so that the flap strength is stronger
		if flapBoostTimer > 0:
			freeVelocity.y += FLAP_HEIGHT * 3.0
			freeVelocity.y = max(freeVelocity.y, FLAP_HEIGHT*3.0)
		else:
			# Scale factor based on how close character is to terminal velocity
			var factor = clamp(freeVelocity.y / TERMINAL_DOWN_VELOCITY, 0.0, 1.0)
			var extraFlapStrength = lerp(0.0, MAX_FLAP_HEIGHT - FLAP_HEIGHT, factor)
			freeVelocity.y += FLAP_HEIGHT + extraFlapStrength	
	else:
		freeVelocity.y += FLAP_HEIGHT
	
	# Record the jump time
	var now = Time.get_ticks_msec()  / 1000.0
	jumpTimes.append(now)

	# zero out timers, otherwise multiple jumps will register
	flapHoverTimer = FLAP_HOVER_TIMER
	#jump_buffer_timer = 0
	#coyote_timer = 0
	stickTimer = STICK_TIMER
	#jump_state.jumping = false
	
#func BufferFlap() -> void:
	#freeVelocity.y = FLAP_HEIGHT
	#
	## Record the jump time
	#var now = Time.get_ticks_msec     ()  / 1000.0
	#jumpTimes.append(now)
#
	## zero out timers, otherwise multiple jumps will register
	#flapHoverTimer = FLAP_HOVER_TIMER
	#jumpBufferTimer = 0
	#coyoteTimer = 0
	#stickTimer = STICK_TIMER
	##jump_state.jumping = false
	
func _process(delta: float) -> void:
	_handle_input()
	_handle_jump_input()
	_handle_dash_input()
	
	_processAll(delta)
	
	_select_state()

	state.do(delta)
	
func _handle_input() -> void:
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		input_dir = MultiplayerInput.get_vector(PLAYER_ID, "move_left", "move_right", "move_up", "move_down")
		

func _handle_jump_input() -> void:
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		input_jump = Input.is_action_just_pressed("jump")
	else:
		input_jump = MultiplayerInput.is_action_just_pressed(PLAYER_ID,"jump")
	
func _handle_dash_input() -> void:
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		input_dash = Input.is_action_just_pressed("dash")
	else:
		input_dash = MultiplayerInput.is_action_just_pressed(PLAYER_ID, "dash")
	
func _select_state() -> void:
	var old_state: State = state
	
	state.is_complete = false
		
	if bounce_state.bounce_timer > 0:
		set_state(bounce_state)
	elif dash_state.dash_timer > 0:
		set_state(dash_state)
	elif grounded:
		if input_dir.x == 0:
			set_state(idle_state)
		else:
			set_state(run_state)
	else:
		if not jump_state.jumping:
			set_state(flap_state)
		else:
			set_state(jump_state)

func set_state(new_state : State, over_ride:bool = false):
	if new_state != null and (state != new_state || over_ride):
		if state != null:
			state.exit()

		state = new_state
		state.initialize()
		state.enter()

#func _start_bounce() -> void:
	#return

#func _start_dash() -> void:
	#return

#func _start_idle() -> void:
	#animated_sprite.play("idle")

#func _start_running() -> void:
	#animated_sprite.play("run")

#func _start_jumping() -> void:
	#animated_sprite.play("jump")

#func _start_flapping() -> void:
	#return
	
	
func _processAll(delta: float) -> void:
	#if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		#return
	#var now = Time.get_ticks_msec()  / 1000.0
	#var inputDir: Vector2
	#if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		#direction = Input.get_axis("move_left", "move_right")
		#inputDir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#else:
		#direction = MultiplayerInput.get_axis(PLAYER_ID, "move_left", "move_right")
		#inputDir = MultiplayerInput.get_vector(PLAYER_ID, "move_left", "move_right", "move_up", "move_down")
		#

	#if is_on_floor() and state != dash_state:
		#canDash = true
	
	HandleTimers(delta)
	
	#if jump_state.jumping and is_on_floor():
		#jump_state.jumping = false
	
	if input_dash and state != dash_state:
		set_state(dash_state)

	### Handle jump and flapping
	# Check if we're allowed to jump by seeing if we're 
	# on the ground or recently left it
	if is_on_floor() || coyote_timer > 0:
		# Jump if the button was pressed or we registered a jump recently
		if input_jump || jump_buffer_timer > 0: 
			jump_state.attempt_jump = true
			set_state(jump_state)
	# If we aren't on the ground, then fly
	else:
		if input_jump:
			#ezHoverTimer = EZ_HOVER_MAINTAIN_RATE
			jump_buffer_timer = JUMP_BUFFER
			if justTouchedCeilingTimer > 0 and not ezHover:
				bufferFlap = true
			else:
				flap_state.attempt_flap = true
				set_state(flap_state)
				
	if bufferFlap and justTouchedCeilingTimer == 0:
		bufferFlap = false
		flap_state.attempt_buffer_flap = true
		set_state(flap_state)
	
	# How fast we can go once we we've hit our max speed
	#if is_on_floor():
		#desiredVelocity =  Vector2(direction, 0) * RUN_SPEED
	#else:
		#desiredVelocity =  Vector2(direction, 0) * AIR_SPEED
	
func HandleStickAndEZHover() -> void:
	### Handle sticking & ez hovering
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
			# Therefore, allow ourselves to "stick", AKA start sticking on the ceiling
			if stickTimer == 0.0:
				sticking = true
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
				# and sticking
				if scrapeBumps > BUMPS_TO_EZ_HOVER:
					ezHover = true
					bufferFlap = false

func HandleTimers(delta) -> void:
	### Handle timers
	if grounded:
		coyote_timer = COYOTO_TIME
	else:
		coyote_timer = max(coyote_timer - delta, 0)
	jump_buffer_timer = max(jump_buffer_timer - delta, 0)
	flapHoverTimer = max(flapHoverTimer - delta, 0.0)
	stickTimer = max(stickTimer - delta, 0)
	scrapeTimer = max(scrapeTimer - delta, 0)
	flapBoostTimer = max(flapBoostTimer - delta, 0)
	justTouchedCeilingTimer = max(justTouchedCeilingTimer - delta, 0) 
	#ezHoverTimer = max(ezHoverTimer - delta, 0) 
	if scrapeTimer == 0:
		scrapeBumps = 0

func HandleCeilingBounce() -> void:
	# If we hit the ceiling then, if we're sticking, don't move upward
	# If we aren't sticking, then bounce off the ceiling with you current
	# upwards desired velocity multiplied by the CEILING_BOUNCINESS of the
	# ceiling
	if is_on_ceiling():
		if not justTouchedCeilingBool and not (sticking or ezHover) :
			justTouchedCeilingBool = true
			justTouchedCeilingTimer = 0.13
			velocityBeforeTouchingCeiling = velocity.y 
				
		if freeVelocity.y > 0:
			sticking = false
			ezHover = false

		if sticking or ezHover:
			velocity.y = 0 
		else:
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				if collision.get_normal().y > 0 and justTouchedCeilingBool:
					#freeVelocity.y += velocity.bounce(collision.get_normal()).y * CEILING_BOUNCINESS
					freeVelocity.y += abs(velocity.y) * CEILING_BOUNCINESS
					velocity.y = freeVelocity.y
	else:
		justTouchedCeilingBool = false

func _physics_process(delta: float) -> void:	
	
	physicsFrame += 1
	
	### Determine ON GROUND speeds / accelerations based on constants 
	#var acceleration = MAX_ACCELERATION if grounded else MAX_AIR_ACCELERATION 
	#var deceleration = MAX_DECELERATION if grounded else MAX_AIR_DECELERATION
	#var turnSpeed    = MAX_TURN_SPEED   if grounded else MAX_AIR_TURN_SPEED
	
	### Determine ON JUMP speeds / accelerations based on constants
	# NOTE These don't rely on "grounded" so we can eventually move these to @onready varaibles
	# Currently done like this to allow us to experiment with different variables in editor   
	#jumpSpeed = JUMP_SPEED
	jumpGravity = JUMP_GRAVITY
	fallGravity = FALL_GRAVITY
	
	# If we're moving up or down then we're not sticking or ez hovering
	if velocity.y != 0.0:
		sticking = false
		ezHover = false
	
	# Add the gravity (to free velocity, not actual movement yet)
	#freeVelocity.y += gravity() * delta
	
	# Clamp player's fall & rise speeds	
	#freeVelocity.y = min(freeVelocity.y, TERMINAL_DOWN_VELOCITY)
	#if not jump_state.jumping and state != dash_state:
		#freeVelocity.y = max(freeVelocity.y, TERMINAL_UP_VELOCITY)
	
	# Horizontal acceleration applied to freeVelocity.x
	#if direction != 0:
		#if(sign(direction) != sign(freeVelocity.x) ):
			#maxSpeedChange = turnSpeed * delta
		#else:
			#maxSpeedChange = acceleration * delta
	#else:
		#maxSpeedChange = deceleration * delta
	#
	#if state != dash_state and state != bounce_state:
		#freeVelocity.x = move_toward(freeVelocity.x, desiredVelocity.x, maxSpeedChange)
	#elif state == bounce_state:
		#freeVelocity = bounceSpeed
	#elif state == dash_state:
		#freeVelocity = dash_state.dash_dir * DASH_SPEED
	
	#if bounce_timer >0:
		#freeVelocity.y = bounceSpeed.y
	#if dash_timer >0:
		#freeVelocity.y = dashDir.y * DASH_SPEED
	#
	# Move the character according to gravity and acceleration. The rest
	# Handles special cases where we're scraping or sticking which sets the velocity.y
	# to 0
	#if dash_timer> 0: 
		#velocity = freeVelocity
	#if dash_timer == 0.0 and hasDashed:
		#velocity = freeVelocity
	#else:
	
	state.physics_do(delta)
	velocity = freeVelocity
	_face_input()
	
	HandleStickAndEZHover()
			
	HandleCeilingBounce()
		
	if ezHover and flap_state.maintain_scrape_timer == 0:
		sticking = false
		ezHover = false
	
	move_and_slide()
	
	grounded = is_on_floor()
	

func _face_input() -> void:
	### flip sprite
	if input_dir.x > 0:
		animated_sprite.flip_h = false
	elif input_dir.x < 0:
		animated_sprite.flip_h = true

func _on_hit_box_body_entered(_body: Node2D) -> void:
	# Ensures only 1 player resolves the collision	
	if get_instance_id() < _body.get_instance_id():
		return
		
	if _body.is_in_group("Player") and _body != self:
		# Check height threshhold. If not met, then it's a bounce
		if abs(abs(global_position.y) - abs(_body.global_position.y))  >= 4.0 and (
			isInteractable == true and _body.isInteractable == true
		):
			_body.deathCounter += 1
			_body.isInteractable = false
			_body.platform_collider.set_deferred("disabled", true)
			_body.animationPlayer.play("die")
		else:	
			var bounceBack = abs(abs(velocity)  + abs(_body.velocity)) * 0.25 
			
			if global_position.x > _body.global_position.x:
				bounce_state.bounceSpeed.x = bounceBack.x
				_body.bounce_statebounceSpeed.x = -bounceBack.x
			else:
				bounce_state.bounceSpeed.x = -bounceBack.x
				_body.bounce_state.bounceSpeed.x = bounceBack.x
	
			bounce_state.bounce_timer = BOUNCE_TIME
			_body.bounce_state.bounce_timer = BOUNCE_TIME

func respawn() -> void:
	isInteractable = true
	platform_collider.set_deferred("disabled", false)
	
