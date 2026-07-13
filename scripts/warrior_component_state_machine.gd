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
@onready var bounce_state     = $states/bounce_state     as BounceState
@onready var crouch_state     = $states/crouch_state     as CrouchState
@onready var dash_state       = $states/dash_state       as DashState
@onready var flap_state       = $states/flap_state       as FlapState
@onready var idle_state       = $states/idle_state       as IdleState
@onready var jump_state       = $states/jump_state       as JumpState
@onready var run_state        = $states/run_state        as RunState
@onready var wall_cling_state = $states/wall_cling_state as WallClingState
@onready var player_input = $input_component     as InputComponent

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

func set_state(new_state : State, over_ride:bool = false):
	if new_state != null and (state != new_state || over_ride):
		if state != null:
			state.exit()
		
		state = new_state
		state.initialize()
		state.enter()
	
func _handle_timers(delta) -> void:
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
	move_and_slide()
	grounded = is_on_floor()
	walled   = is_on_wall()
	
	if grounded and dash_cooldown_timer == 0:
		dash_state.can_dash = true

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
	
