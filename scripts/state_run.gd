class_name RunState extends State

@export var RUN_SPEED := 180.0 
@export var MAX_ACCELERATION := 900.0
@export var MAX_TURN_SPEED := 3000.0
@export var run_sound: AudioStream
@onready var run_dust_1: GPUParticles2D = %RunParticle
@onready var run_dust_2: GPUParticles2D = %RunParticle2
var dust_index: int = 0

func enter() -> void:
	#print("run")
	if body.has_berry:
		animated_sprite.play("run")
	else:
		animated_sprite.play("run")
	state_label.text = "run"
	#play_sound(run_sound, 10.0, 0.3)
	emit_dust()
	
func do(delta: float) -> void:	
	if !body.grounded or input.get_movement_direction(body.PLAYER_ID).x == 0:
		is_complete = true
	return

func physics_do(delta: float) -> void:
	var max_speed_change
	var input_x = input.get_movement_direction(body.PLAYER_ID).x
	
	var desired_velocity =  Vector2(input_x, 0) * RUN_SPEED
	
	if(sign(input_x) != sign(body.freeVelocity.x) ):
		max_speed_change = MAX_TURN_SPEED * delta
	else:
		max_speed_change = MAX_ACCELERATION * delta
		
	body.freeVelocity.x = move_toward(body.freeVelocity.x, desired_velocity.x, max_speed_change)
	
	body.velocity = body.freeVelocity

func emit_dust():
	if dust_index == 0:
		run_dust_1.restart()
	else:
		run_dust_2.restart()
	dust_index = (dust_index + 1) % 2


func exit() -> void:
	return
