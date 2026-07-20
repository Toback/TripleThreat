class_name IdleState extends State
@export var MAX_DECELERATION := 1500.0

func enter() -> void:
	#print("idle")
	if body.has_berry:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("idle")
	state_label.text = "idle"
	
func do(delta: float) -> void:
	body.freeVelocity.x = move_toward(body.freeVelocity.x, 0,  MAX_DECELERATION * delta)
	body.velocity = body.freeVelocity
	
	if !body.grounded or input.get_movement_direction(body.PLAYER_ID).x != 0:
		is_complete = true
	return

func physics_do(_delta: float) -> void:
	return

func exit() -> void:
	return
