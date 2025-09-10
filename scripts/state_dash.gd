class_name DashState extends State

@export var DASH_SPEED := 400.0
@export var DASH_TIME := 0.3
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var can_dash: bool 
var has_dashed: bool

func enter() -> void:
	dash_timer = DASH_TIME
	dash_dir = Helpers.get_snapped_direction(input.get_movement_direction())
	can_dash = false
	has_dashed = true
	state_label.text = "dashing"

	
func do() -> void:
	#print("dashing")
	dash_timer = max(DASH_TIME - time, 0)
	if dash_timer == 0:
		is_complete = true
	return

func fixed_do() -> void:
	push_warning("_fixed_do not implemented")

func exit() -> void:
	dash_timer = 0.0
	#can_dash = false
	
