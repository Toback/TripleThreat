class_name BounceState extends State

@export var BOUNCE_TIME := 0.5
var bounce_timer: float = 0.0

func enter() -> void:
	bounce_timer = BOUNCE_TIME
	state_label.text = "bouncing"
	
func do() -> void:
	#print("bouncing")
	bounce_timer = max(BOUNCE_TIME - time, 0)
	if bounce_timer == 0:
		is_complete = true
	return

#func fixed_do() -> void:
	#push_warning("_fixed_do not implemented")
#
func exit() -> void:
	bounce_timer = 0.0
