class_name LedgeGrabState extends State
var current_gravity: float
var input_jump: bool
var input_x: float
var playing_animation: bool = false
var ledge_grab_timer: float = 0.0
var upwards_thrust_timer: float = 0.0
var climb_start: Vector2
var climb_end: Vector2
var climb_end_2: Vector2
var facing_direction: Vector2
var corner_location: Vector2
var ledge_snap_offset: Vector2 = Vector2(4,-12)
var stored_velocity: Vector2
@export var LEDGE_GRAB_DURATION := 0.1
@export var UPWARDS_THRUST_DURATION := 0.06
@export var ledge_grab_sound: AudioStream

func enter() -> void:
	#print("wall")
	state_label.text = "ledge_grab"
	animated_sprite.play("ledge_grab")
	stored_velocity = body.velocity
	playing_animation = true
	facing_direction = body.current_facing_direction()
	climb_start = Vector2(
		corner_location.x - ledge_snap_offset.x * facing_direction.x,
		min(corner_location.y - ledge_snap_offset.y, body.global_position.y),
	) 
	climb_end = climb_start + Vector2(0, -13)
	climb_end_2 = climb_end + Vector2(12 * facing_direction.x, -5)
	ledge_grab_timer = LEDGE_GRAB_DURATION
	upwards_thrust_timer = UPWARDS_THRUST_DURATION
	body.global_position = climb_start
	body.velocity = Vector2.ZERO
	body.freeVelocity = Vector2.ZERO
	print("climb start ", climb_start, " climb end ", climb_end)
	play_sound(ledge_grab_sound, -25.0, 0.0, 0.5)
	
func do(delta: float) -> void:	
	input_x = input.get_movement_direction(body.PLAYER_ID).x
	input_jump = input.wants_hold_jump(body.PLAYER_ID)
	if ledge_grab_timer == 0:
		upwards_thrust_timer = max(upwards_thrust_timer - delta, 0)
	ledge_grab_timer = max(ledge_grab_timer - delta, 0)
	if upwards_thrust_timer == 0:
		is_complete = true
	return
	
func physics_do(delta: float) -> void:
	var t
	if ledge_grab_timer > 0:
		t = clamp(ledge_grab_timer / LEDGE_GRAB_DURATION, 0.0, 1.0)
		body.global_position = climb_end.lerp(climb_start, t)
	if ledge_grab_timer == 0 and upwards_thrust_timer > 0:
		t = clamp(upwards_thrust_timer / UPWARDS_THRUST_DURATION, 0.0, 1.0)
		body.global_position = climb_end_2.lerp(climb_end, t)
	print(t, body.global_position)
	body.freeVelocity.y += gravity() * delta

func exit() -> void:
	stop_sound()
	#body.wall_jump_grace_timer = body.WALL_JUMP_GRACE_TIME
	playing_animation = false
	body.velocity = stored_velocity
	return
