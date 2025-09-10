class_name IdleState extends State

func enter() -> void:
	animated_sprite.play("idle")
	state_label.text = "idle"
	
func do() -> void:
	#print("idling")
	#if !grounded or input_dir.x != 0 or dash_timer > 0 or bounce_timer > 0:
	if !body.grounded or input.get_movement_direction().x != 0:
		is_complete = true
	return

func fixed_do() -> void:
	push_warning("_fixed_do not implemented")

func exit() -> void:
	push_warning("_exit not implemented")
