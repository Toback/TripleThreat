class_name BounceState extends State

@export var BOUNCE_TIME := 0.5
var bounce_timer: float = 0.0
var bounce_speed: float = 0.0


func enter() -> void:
	print("bounce")
	bounce_timer = BOUNCE_TIME
	state_label.text = "bouncing"
	
func do(delta: float) -> void:
	#print("bouncing")
	
	#body.freeVelocity.y += gravity() * delta
	
	bounce_timer = max(BOUNCE_TIME - time, 0)
	#body.freeVelocity = bounce_speed
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
