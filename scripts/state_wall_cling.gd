class_name WallClingState extends State
var current_gravity: float
var input_jump: bool
var input_x: float
@export var WALL_CLING_GRAVITY_DOWN := 150
@export var WALL_CLING_GRAVITY_UP := 400
@export var WALL_CLING_GRAVITY_UP_BUT_LET_GO_OF_JUMP := 2000.0
@export var WALL_CLING_SPEED_TO_MAX_GRAVITY := 20000.0

func enter() -> void:
	print("wall")
	state_label.text = "wall"
	
func do(_delta: float) -> void:	
	input_x = input.get_movement_direction(body.PLAYER_ID).x
	input_jump = input.wants_hold_jump(body.PLAYER_ID)
	if  !body.left_wall_cling_ray.is_colliding() or \
		!body.right_wall_cling_ray.is_colliding() or \
		(body.left_wall_cling_ray.is_colliding() and input_x > -0.5) or \
		 (body.right_wall_cling_ray.is_colliding() and input_x < 0.5):
		is_complete = true
	return
	
func physics_do(delta: float) -> void:
	print(gravity())
	body.freeVelocity.y += gravity() * delta

func gravity() -> float:
	# check if our character is going up. Godot has UP being negative y.
	if body.freeVelocity.y < 0.0 :
		# hold the jump button down to jump higher 
		if input_jump:
			current_gravity = WALL_CLING_GRAVITY_UP
			return WALL_CLING_GRAVITY_UP 
			# when you let go of the jump button while rising, you fall down at a faster fall gravity
		else:
			# Ease to the max fall gravity. Can set SPEED_TO_MAX_GRAVITY really high to just
			# go immediately to the fallGravity speed
			current_gravity = move_toward(current_gravity, WALL_CLING_GRAVITY_UP_BUT_LET_GO_OF_JUMP, WALL_CLING_SPEED_TO_MAX_GRAVITY)
			#currentGravity = fallGravity
			return current_gravity
	# once you start falling, fall down faster
	else:
		current_gravity = WALL_CLING_GRAVITY_DOWN
		return current_gravity
	
	#if body.freeVelocity.y < 0:
		#return WALL_CLING_GRAVITY_UP
	#else:
		#return WALL_CLING_GRAVITY_DOWN

func exit() -> void:
	return
