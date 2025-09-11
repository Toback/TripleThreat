class_name RunState extends State

@export var RUN_SPEED := 180.0 
@export var MAX_ACCELERATION := 900.0
@export var MAX_TURN_SPEED := 3000.0

func enter() -> void:
	print("run")
	animated_sprite.play("run")
	state_label.text = "run"
	
func do(delta: float) -> void:
	if !body.grounded or input.get_movement_direction().x == 0:
		is_complete = true
	return

func fixed_do(delta: float) -> void:
	var max_speed_change
	var input_x = input.get_movement_direction().x
	
	var desired_velocity =  Vector2(input_x, 0) * RUN_SPEED
	
	body.freeVelocity.y += gravity() * delta
	
	if(sign(input_x) != sign(body.freeVelocity.x) ):
		max_speed_change = MAX_TURN_SPEED * delta
	else:
		max_speed_change = MAX_ACCELERATION * delta
		
	body.freeVelocity.x = move_toward(body.freeVelocity.x, desired_velocity.x, max_speed_change)
	
	body.velocity = body.freeVelocity

func exit() -> void:
	push_warning("_exit not implemented")
