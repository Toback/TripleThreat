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
@export var EZ_HOVER_MAINTAIN_RATE := 0.25 # 4 times a second
@export var CEILING_FLAP_BOOST_TIMER := 0.2
@export_range(0.0, 3.0, 0.05) var CEILING_BOUNCINESS: float = 1.1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ceilingRayCast: RayCast2D = $CeilingRay
@onready var timer: Timer = %Timer
@onready var jRayCast: RayCast2D = $JRay
@onready var animationPlayer: AnimationPlayer = $AnimationPlayer
@onready var platform_collider: CollisionShape2D = $PlatformCollider
@onready var hitBox: Area2D = $HitBox

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
var ezHoverTimer: float
var stickTimer: float
var dashTimer: float
var dashDir: Vector2 = Vector2.ZERO
var sticking: bool = false
var ezHover: bool = false
var freeVelocity: Vector2 = Vector2.ZERO
var jumping: bool = false
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
var canDash: bool = true
var hasDashed: bool = false
var isInteractable: bool = true

#var bounceSpeedX: float = 0.0
#var bounceSpeedY: float = 0.0
var bounceSpeed: Vector2 = Vector2.ZERO
var bounceTimer: float = 0.0
			

func _ready() -> void:
	#timer.start()
	#timer.timeout.connect(_on_timer_timeout)
	#hitBox.body_entered.connect(enterHitbox)
	print("ready called")
#
#func _on_timer_timeout() -> void:
	##print("TICK at: ", Time.get_ticks_msec() / 1000.0)
	#var ev := InputEventAction.new()
	#ev.action = "jump"
	#ev.pressed = true
	#Input.parse_input_event(ev)
#
	## Optionally also simulate "release" right away (tap behavior):
	#var ev_release := InputEventAction.new()
	#ev_release.action = "jump"
	#ev_release.pressed = false
	#Input.parse_input_event(ev_release)

func tryingToJ():
	if jRayCast.is_colliding() and not ceilingRayCast.is_colliding():
		return true
	return false
		
func gravity() -> float:
	if dashTimer > 0:
		return 0
	
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
		if not Input.get_joy_name(0) or not Input.get_joy_name(1):
			if Input.is_action_pressed("jump"):
				currentGravity = jumpGravity
				return currentGravity 
				# when you let go of the jump button while rising, you fall down at a faster fall gravity
			else:
				# Ease to the max fall gravity. Can set SPEED_TO_MAX_GRAVITY really high to just
				# go immediately to the fallGravity speed
				currentGravity = move_toward(currentGravity, fallGravity, SPEED_TO_MAX_GRAVITY)
				#currentGravity = fallGravity
				return currentGravity
		else:	
			if MultiplayerInput.is_action_pressed(PLAYER_ID, "jump"):
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
		
func jumpsPerSecond() -> float:
	var now = Time.get_ticks_msec()  / 1000.0
	var window = 1.0  # 1-second rolling window
	
	# Remove jumps older than the window
	jumpTimes = jumpTimes.filter(func(t): return t >= now - window)

	var duration: float
	if jumpTimes.size() > 0: 
		duration = max(jumpTimes[-1] - jumpTimes[0], 0.2)
		if duration <= 0.0:
			return 0.0  # Prevent division by zero	
	else: 
		return 0.0
	
	# Jumps per second
	return float(jumpTimes.size()) / duration

func Jump() -> void:
	freeVelocity.y = jumpSpeed
	# zero out timers, otherwise multiple jumps will register
	jumpBufferTimer = 0
	coyoteTimer = 0
	jumping = true
	

func get_snapped_direction(raw_dir: Vector2) -> Vector2:
	# Get angle in radians
	var angle := raw_dir.angle()
	
	# Snap to nearest 45° (PI/4 radians)
	var snapped_angle = round(angle / (PI/4.0)) * (PI/4.0)
	
	# Convert back to Vector2
	return Vector2.RIGHT.rotated(snapped_angle).normalized()
	
func Dash(inputDir: Vector2) -> void:
	dashTimer = DASH_TIME
	dashDir = get_snapped_direction(inputDir)	
	canDash = false
	hasDashed = true
	jumping = false

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
	jumpBufferTimer = 0
	coyoteTimer = 0
	stickTimer = STICK_TIMER
	jumping = false
	
func BufferFlap() -> void:
	freeVelocity.y = FLAP_HEIGHT
	
	# Record the jump time
	var now = Time.get_ticks_msec     ()  / 1000.0
	jumpTimes.append(now)

	# zero out timers, otherwise multiple jumps will register
	flapHoverTimer = FLAP_HOVER_TIMER
	jumpBufferTimer = 0
	coyoteTimer = 0
	stickTimer = STICK_TIMER
	jumping = false
	
func _process(delta: float) -> void:
	#if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		#return
	#var now = Time.get_ticks_msec()  / 1000.0
	var inputDir: Vector2
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		direction = Input.get_axis("move_left", "move_right")
		inputDir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		direction = MultiplayerInput.get_axis(PLAYER_ID, "move_left", "move_right")
		inputDir = MultiplayerInput.get_vector(PLAYER_ID, "move_left", "move_right", "move_up", "move_down")
		

	if is_on_floor() and dashTimer == 0:
		canDash = true
	
	HandleTimers(delta)
	
	if jumping and is_on_floor():
		jumping = false
	
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		if Input.is_action_just_pressed("dash") and canDash:
			Dash(inputDir)
	else:
		if MultiplayerInput.is_action_just_pressed(PLAYER_ID, "dash") and canDash:
			Dash(inputDir)
	### Handle jump and flapping
	# Check if we're allowed to jump by seeing if we're 
	# on the ground of recently left it
	if is_on_floor() || coyoteTimer > 0:
		# Jump if the button was pressed or we registered a jump recently
		if not Input.get_joy_name(0) or not Input.get_joy_name(1):
			if Input.is_action_just_pressed("jump") || jumpBufferTimer > 0: 
				Jump()
		else:
			if MultiplayerInput.is_action_just_pressed(PLAYER_ID,"jump") || jumpBufferTimer > 0: 
				Jump()	
	# If we aren't allowed to jump, then fly
	else:
		if not Input.get_joy_name(0) or not Input.get_joy_name(1):
			if Input.is_action_just_pressed("jump"):
				ezHoverTimer = EZ_HOVER_MAINTAIN_RATE
				if justTouchedCeilingTimer > 0 and not ezHover:
					bufferFlap = true
				else:
					Flap()
		else:
			if MultiplayerInput.is_action_just_pressed(PLAYER_ID, "jump"):
				ezHoverTimer = EZ_HOVER_MAINTAIN_RATE
				if justTouchedCeilingTimer > 0 and not ezHover:
					bufferFlap = true
				else:
					Flap()
				
	if bufferFlap and justTouchedCeilingTimer == 0:
		print("Buffered")
		bufferFlap = false
		BufferFlap()	
	
	# How fast we can go once we we've hit our max speed
	if is_on_floor():
		desiredVelocity =  Vector2(direction, 0) * RUN_SPEED
	else:
		desiredVelocity =  Vector2(direction, 0) * AIR_SPEED
	
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
	var onGround = is_on_floor()
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
	ezHoverTimer = max(ezHoverTimer - delta, 0) 
	if scrapeTimer == 0:
		scrapeBumps = 0
	dashTimer = max(dashTimer - delta, 0)
	bounceTimer = max(bounceTimer - delta, 0)

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
					freeVelocity.y += abs(velocity.y) * CEILING_BOUNCINESS
					velocity.y = freeVelocity.y
	else:
		justTouchedCeilingBool = false

func _physics_process(delta: float) -> void:	
	physicsFrame += 1
	#if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		#return
	var onGround = is_on_floor()
	
	### Determine ON GROUND speeds / accelerations based on constants 
	var acceleration = MAX_ACCELERATION if onGround else MAX_AIR_ACCELERATION 
	var deceleration = MAX_DECELERATION if onGround else MAX_AIR_DECELERATION
	var turnSpeed    = MAX_TURN_SPEED   if onGround else MAX_AIR_TURN_SPEED
	
	### Determine ON JUMP speeds / accelerations based on constants
	# NOTE These don't rely on "onGround" so we can eventually move these to @onready varaibles
	# Currently done like this to allow us to experiment with different variables in editor   
	jumpSpeed = JUMP_SPEED
	jumpGravity = JUMP_GRAVITY
	fallGravity = FALL_GRAVITY
	
	# If we're moving up or down then we're not sticking or ez hovering
	if velocity.y != 0.0:
		sticking = false
		ezHover = false
	
	# Add the gravity (to free velocity, not actual movement yet)
	freeVelocity.y += gravity() * delta
	
	# Clamp player's fall & rise speeds	
	freeVelocity.y = min(freeVelocity.y, TERMINAL_DOWN_VELOCITY)
	if not jumping and not dashTimer > 0:
		freeVelocity.y = max(freeVelocity.y, TERMINAL_UP_VELOCITY)
	
	# Horizontal acceleration applied to freeVelocity.x
	if direction != 0:
		if(sign(direction) != sign(freeVelocity.x) ):
			maxSpeedChange = turnSpeed * delta
		else:
			maxSpeedChange = acceleration * delta
	else:
		maxSpeedChange = deceleration * delta
	
	if dashTimer == 0 and bounceTimer == 0:
		freeVelocity.x = move_toward(freeVelocity.x, desiredVelocity.x, maxSpeedChange)
	elif bounceTimer > 0:
		freeVelocity = bounceSpeed
	elif dashTimer > 0:
		freeVelocity = dashDir * DASH_SPEED
	
	#if bounceTimer >0:
		#freeVelocity.y = bounceSpeed.y
	#if dashTimer >0:
		#freeVelocity.y = dashDir.y * DASH_SPEED
	#
	# Move the character according to gravity and acceleration. The rest
	# Handles special cases where we're scraping or sticking which sets the velocity.y
	# to 0
	#if dashTimer> 0: 
		#velocity = freeVelocity
	#if dashTimer == 0.0 and hasDashed:
		#velocity = freeVelocity
	#else:
	velocity = freeVelocity
	
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
	
	#HandleStickAndEZHover()
			
	#HandleCeilingBounce()
		
	if ezHover and ezHoverTimer == 0:
		sticking = false
		ezHover = false

	move_and_slide()
	
	#for i in range(get_slide_collision_count()):
		#var collision = get_slide_collision(i)
		#var other = collision.get_collider()
		## Only check collisions with other players
		#if other.is_in_group("Player"):
			#print("p1 ", global_position, " p2 ", other.global_position)
			#resolve_collision(self, other)
			#break


#func resolve_collision(p1: Node2D, p2: Node2D) -> void:
#
	##elif p1.global_position.y > p2.global_position.y:
		##p1.deathCounter += 1
		##print("p1 died ", p1.deathCounter, " times")
		##p1.platform_collider.disabled = true
		##p1.animationPlayer.play("die")

#func Respawn():
	## Reset position and velocity
	##queue_free()
	##var new_player = preload("res://scenes/warriorDashing.tscn").instantiate()
	##get_tree().current_scene.add_child(new_player)
	##new_player.PLAYER_ID = PLAYER_ID
	#new_player.global_position = Vector2(155, -130)

func _on_hit_box_body_entered(_body: Node2D) -> void:
	if get_instance_id() < _body.get_instance_id():
		return
	if _body.is_in_group("Player") and _body != self:
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
				bounceSpeed.x = bounceBack.x
				_body.bounceSpeed.x = -bounceBack.x
				#
			else:
				bounceSpeed.x = -bounceBack.x
				_body.bounceSpeed.x = bounceBack.x

			
			bounceTimer = BOUNCE_TIME
			_body.bounceTimer = BOUNCE_TIME

func respawn() -> void:
	isInteractable = true
	platform_collider.set_deferred("disabled", false)
	
