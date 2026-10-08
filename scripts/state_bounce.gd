class_name BounceState extends State

var bounce_timer: float = 0.0
var bounce_speed: Vector2
@export var BOUNCE_TIME := 0.5
@export var bounce_sound: AudioStream

func enter() -> void:
	#print("bounce")
	bounce_timer = BOUNCE_TIME
	animated_sprite.play("bounce")
	play_sound(bounce_sound, 10.0)
	state_label.text = "bouncing"
	
func do(_delta: float) -> void:
	bounce_timer = max(BOUNCE_TIME - time, 0)
	if bounce_timer == 0:
		is_complete = true
	return

func physics_do(delta: float) -> void:
	body.freeVelocity.y += gravity() * delta
	body.freeVelocity = bounce_speed
	return
#
func exit() -> void:
	bounce_timer = 0.0

func gravity() -> float:
	return 0.0
