class_name FlapState extends State

@export var FLAP_HEIGHT := -30.0
@export var MAX_FLAP_HEIGHT := -100.0
@export var FLAP_HOVER_GRAVITY := 20.0
@export var FLAP_HOVER_TIMER := 0.15
@export var CEILING_FLAP_BOOST_TIMER := 0.2

func enter() -> void:
	state_label.text = "flapping"
	return
	
func do() -> void:
	#print("flapping")
	#if grounded or dash_timer > 0 or bounce_timer > 0:
	if body.grounded:
		is_complete = true
	return

func fixed_do() -> void:
	push_warning("_fixed_do not implemented")

func exit() -> void:
	push_warning("_exit not implemented")
