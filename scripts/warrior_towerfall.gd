extends CharacterBody2D

var coyote_timer: float
var dash_coyote_timer: float
var jump_buffer_timer: float
var dash_cooldown_timer: float
var freeVelocity: Vector2 = Vector2.ZERO
var physics_frame: int = 0
var is_interactable: bool = true
var bounce_speed: Vector2 = Vector2.ZERO
var state: State
var input_dir: Vector2
var input_jump: bool
var input_dash: bool
var grounded: bool = false
var walled: bool = false
var has_berry: bool = false

@onready var wrap_bounds: ReferenceRect = get_tree().get_first_node_in_group("WrapBounds")

@export var PLAYER_ID := 0 
@export var COYOTO_TIME := 0.05 # Always let warriors start with a big jump in the air
@export var BOUNCE_TIME := 0.5

@onready var berry_sprite: Sprite2D = $BerrySprite
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var platform_collider: CollisionShape2D = $PlatformCollider
@onready var left_wall_cling_ray: RayCast2D = $left_wall_cling_ray
@onready var right_wall_cling_ray: RayCast2D = $right_wall_cling_ray
@onready var state_label: Label = $StateLabel
@onready var bounce_state: BounceState        = $states/bounce_state 
@onready var crouch_state: CrouchState        = $states/crouch_state
@onready var dash_state: DashState            = $states/dash_state
@onready var flap_state: FlapState            = $states/flap_state     
@onready var idle_state: IdleState            = $states/idle_state 
@onready var jump_state: JumpState            = $states/jump_state
@onready var run_state: RunState              = $states/run_state
@onready var wall_cling_state: WallClingState = $states/wall_cling_state
@onready var player_input: InputComponent     = $input_component

func _ready() -> void:
	bounce_state.setup(self, animated_sprite, player_input, state_label)
	crouch_state.setup(self, animated_sprite, player_input, state_label)
	dash_state.setup(self, animated_sprite, player_input, state_label)
	flap_state.setup(self, animated_sprite, player_input, state_label)
	idle_state.setup(self, animated_sprite, player_input, state_label)
	jump_state.setup(self, animated_sprite, player_input, state_label)
	run_state.setup(self, animated_sprite, player_input, state_label)
	wall_cling_state.setup(self, animated_sprite, player_input, state_label)
	state = idle_state
	
func _process(delta: float) -> void:
	if Global.game_state != Global.GameState.PLAYING:
		return
	input_dir = player_input.get_movement_direction(PLAYER_ID)
	input_jump = player_input.wants_jump(PLAYER_ID)
	input_dash = player_input.wants_dash(PLAYER_ID)
	 
	#hair.update_hair(global_position, current_facing_direction().x)
	#print("warrior ",global_position)
	_handle_berry_sprite()
	_handle_timers(delta)
	
	if input_dash and dash_state.can_dash:
		if grounded:
			dash_state.dashed_from_ground = true
		if state == crouch_state:
			dash_state.dashed_from_crouch = true
		set_state(dash_state)

	### Handle jump and flapping
	# Check if we're allowed to jump by seeing if we're 
	# on the ground or recently left it
	if grounded || coyote_timer > 0 || dash_coyote_timer > 0 || (left_wall_cling_ray.is_colliding() and not has_berry) || (right_wall_cling_ray.is_colliding() and not has_berry):
		# Jump if the button was pressed or we registered a jump recently
		if input_jump || jump_buffer_timer > 0: 
			jump_state.attempt_jump = true
			set_state(jump_state, true)
	# If we aren't on the ground, then fly
	else:
		if input_jump and not has_berry:
			flap_state.attempt_flap = true
			if state != dash_state:
				set_state(flap_state)
	
	_select_state()

	state.do(delta)
		
func _select_state() -> void:	
	state.is_complete = false
	
	if bounce_state.bounce_timer > 0:
		set_state(bounce_state)
	elif dash_state.dash_timer > 0:
		set_state(dash_state)
	elif grounded:
		if input_dir.y >= 0.5:
			set_state(crouch_state)
		elif input_dir.x == 0:
			set_state(idle_state)
		else:
			set_state(run_state)
	elif ((left_wall_cling_ray.is_colliding()  and input_dir.x < -0.5) or
		  (right_wall_cling_ray.is_colliding() and input_dir.x >  0.5)) and jump_state.wall_jump_timer == 0 and not has_berry:
		set_state(wall_cling_state)
	else:
		if not jump_state.jumping:
			set_state(flap_state)
		else:
			set_state(jump_state)

func set_state(new_state : State, over_ride:bool = false) -> void:
	if new_state != null and (state != new_state || over_ride):
		if state != null:
			state.exit()
		
		state = new_state
		state.initialize()
		state.enter()
	
func _handle_timers(delta: float) -> void:
	### Handle timers
	if grounded:
		coyote_timer = COYOTO_TIME
	else:
		coyote_timer = max(coyote_timer - delta, 0)
	dash_coyote_timer = max(dash_coyote_timer - delta, 0)
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0)
	jump_buffer_timer = max(jump_buffer_timer - delta, 0)
	
func _handle_berry_sprite() -> void:
	if has_berry:
		berry_sprite.visible = true
		if current_facing_direction() == Vector2.LEFT:
			berry_sprite.flip_h = true
			berry_sprite.offset.x = 16 
		else:
			berry_sprite.flip_h = false
			berry_sprite.offset.x = -16
	else:
		berry_sprite.visible = false
		


func _physics_process(delta: float) -> void:	
	physics_frame += 1
	state.physics_do(delta)
	
	velocity = freeVelocity
	
	_face_input()
	_wrap_character()
	move_and_slide()
	grounded = is_on_floor()
	walled   = is_on_wall()
	
	if grounded and dash_cooldown_timer == 0:
		dash_state.can_dash = true

#func _wrap_character() -> void:
	## Horizontal wrap
	#if global_position.x < -wrap_bounds.size.x/2:
		#global_position.x += wrap_bounds.size.x
	#elif global_position.x > wrap_bounds.size.x/2:
		#global_position.x -= wrap_bounds.size.x
#
	## Vertical wrap
	#if global_position.y < -wrap_bounds.size.y/2:
		#global_position.y += wrap_bounds.size.y
	#elif global_position.y > wrap_bounds.size.y/2:
		#global_position.y -= wrap_bounds.size.y
		
var last_wrap_direction := Vector2i.ZERO
var wrap_margin := 20.0


func _wrap_character() -> void:
	var half_width = wrap_bounds.size.x / 2
	var half_height = wrap_bounds.size.y / 2

	var wrap_direction := Vector2i.ZERO

	# Determine horizontal wrap thresholds
	var left_limit = -half_width
	var right_limit = half_width

	# Determine vertical wrap thresholds
	var top_limit = -half_height
	var bottom_limit = half_height

	# Add margin if we just wrapped in the opposite direction
	if last_wrap_direction.x > 0:
		right_limit += wrap_margin
	elif last_wrap_direction.x < 0:
		left_limit -= wrap_margin

	if last_wrap_direction.y > 0:
		bottom_limit += wrap_margin
	elif last_wrap_direction.y < 0:
		top_limit -= wrap_margin


	# Horizontal wrap
	if global_position.x < left_limit:
		global_position.x += wrap_bounds.size.x
		wrap_direction.x = -1

	elif global_position.x > right_limit:
		global_position.x -= wrap_bounds.size.x
		wrap_direction.x = 1


	# Vertical wrap
	if global_position.y < top_limit:
		global_position.y += wrap_bounds.size.y
		wrap_direction.y = -1

	elif global_position.y > bottom_limit:
		global_position.y -= wrap_bounds.size.y
		wrap_direction.y = 1


	# Store the most recent wrap direction
	if wrap_direction != Vector2i.ZERO:
		last_wrap_direction = wrap_direction


	# Clear the restriction once we're safely back inside
	if (
		global_position.x > -half_width + wrap_margin and
		global_position.x < half_width - wrap_margin and
		global_position.y > -half_height + wrap_margin and
		global_position.y < half_height - wrap_margin
	):
		last_wrap_direction = Vector2i.ZERO

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
			is_interactable and _body.is_interactable
		):
			_body.is_interactable = false
			_body.platform_collider.set_deferred("disabled", true)
			_body.animation_player.play("die")
		else:	
			var bounce_back = abs(abs(velocity)  + abs(_body.velocity)) * 0.25 
			
			if global_position.x > _body.global_position.x:
				bounce_state.bounce_speed.x = bounce_back.x
				_body.bounce_state.bounce_speed.x = -bounce_back.x
			else:
				bounce_state.bounce_speed.x = -bounce_back.x
				_body.bounce_state.bounce_speed.x = bounce_back.x
	
			bounce_state.bounce_timer = BOUNCE_TIME
			_body.bounce_state.bounce_timer = BOUNCE_TIME

func respawn() -> void:
	is_interactable = true
	platform_collider.set_deferred("disabled", false)

func current_facing_direction() -> Vector2:
	if animated_sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT
	
