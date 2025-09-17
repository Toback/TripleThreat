extends CharacterBody2D

var coyote_timer: float
var jump_buffer_timer: float
var freeVelocity: Vector2 = Vector2.ZERO
var physics_frame: int = 0
var is_interactable: bool = true
var bounce_speed: Vector2 = Vector2.ZERO
var state: State
var input_dir: Vector2
var input_jump: bool
var input_dash: bool
var grounded: bool = false

@export var PLAYER_ID := 0 
@export var COYOTO_TIME := 0.05
@export var BOUNCE_TIME := 0.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var platform_collider: CollisionShape2D = $PlatformCollider
@onready var state_label: Label = $StateLabel
@onready var bounce_state = $states/bounce_state as BounceState
@onready var dash_state   = $states/dash_state   as DashState
@onready var flap_state   = $states/flap_state   as FlapState
@onready var idle_state   = $states/idle_state   as IdleState
@onready var jump_state   = $states/jump_state   as JumpState
@onready var run_state    = $states/run_state    as RunState
@onready var player_input = $input_component     as InputComponent

func _ready() -> void:
	bounce_state.setup(self, animated_sprite, player_input, state_label)
	dash_state.setup(self, animated_sprite, player_input, state_label)
	flap_state.setup(self, animated_sprite, player_input, state_label)
	idle_state.setup(self, animated_sprite, player_input, state_label)
	jump_state.setup(self, animated_sprite, player_input, state_label)
	run_state.setup(self, animated_sprite, player_input, state_label)
	state = idle_state
	
func _process(delta: float) -> void:
	input_dir = player_input.get_movement_direction(PLAYER_ID)
	input_jump = player_input.wants_jump(PLAYER_ID)
	input_dash = player_input.wants_dash(PLAYER_ID)
	
	_handle_timers(delta)
	
	if input_dash:
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
			flap_state.attempt_flap = true
			set_state(flap_state)
	
	_select_state()

	state.do(delta)
		
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
	
func _handle_timers(delta) -> void:
	### Handle timers
	if grounded:
		coyote_timer = COYOTO_TIME
	else:
		coyote_timer = max(coyote_timer - delta, 0)
	jump_buffer_timer = max(jump_buffer_timer - delta, 0)

func _physics_process(delta: float) -> void:	
	physics_frame += 1
	state.physics_do(delta)
	
	velocity = freeVelocity
	
	_face_input()
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
			is_interactable and _body.is_interactable
		):
			_body.deathCounter += 1
			_body.is_interactable = false
			_body.platform_collider.set_deferred("disabled", true)
			_body.animation_player.play("die")
		else:	
			var bounce_back = abs(abs(velocity)  + abs(_body.velocity)) * 0.25 
			
			if global_position.x > _body.global_position.x:
				bounce_state.bounce_speed.x = bounce_back.x
				_body.bounce_statebounce_speed.x = -bounce_back.x
			else:
				bounce_state.bounce_speed.x = -bounce_back.x
				_body.bounce_state.bounce_speed.x = bounce_back.x
	
			bounce_state.bounce_timer = BOUNCE_TIME
			_body.bounce_state.bounce_timer = BOUNCE_TIME

func respawn() -> void:
	is_interactable = true
	platform_collider.set_deferred("disabled", false)
	
