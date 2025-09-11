class_name IdleState extends State
@export var MAX_DECELERATION := 700.0

func enter() -> void:
	print("idle")
	animated_sprite.play("idle")
	state_label.text = "idle"
	
func do(delta: float) -> void:
	#print("idling")
	#if !grounded or input_dir.x != 0 or dash_timer > 0 or bounce_timer > 0:
	#body.freeVelocity.y += gravity() * delta
	
	body.freeVelocity.x = move_toward(body.freeVelocity.x, 0,  MAX_DECELERATION * delta)
	
	body.velocity = body.freeVelocity
	
	if !body.grounded or input.get_movement_direction().x != 0:
		is_complete = true
	return

func fixed_do(delta: float) -> void:
	body.freeVelocity.y += gravity() * delta
	push_warning("_fixed_do not implemented")

func exit() -> void:
	push_warning("_exit not implemented")
