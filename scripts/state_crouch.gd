class_name CrouchState extends State
@export var CROUCH_DECELERATION := 3000.0
@export var crouch_sound: AudioStream

func enter() -> void:
	#print("crouch")
	state_label.text = "crouch"
	animated_sprite.play("crouch")
	play_sound(crouch_sound, 0.0)
	
func do(delta: float) -> void:
	body.freeVelocity.x = move_toward(body.freeVelocity.x, 0,  CROUCH_DECELERATION * delta)
	body.velocity = body.freeVelocity
	
	if !body.grounded or input.get_movement_direction(body.PLAYER_ID).y != 1:
		is_complete = true
	return

func physics_do(_delta: float) -> void:
	return

func exit() -> void:
	if !input.wants_dash(body.PLAYER_ID):
		play_sound(crouch_sound, -10.0, 0.0, 0.3)
	return
