class_name JumpState extends State

@export var JUMP_SPEED := -250.0
var jumping: bool
var jump_speed: float

func enter() -> void:
	animated_sprite.play("jump")
	state_label.text = "jump"
	
func do() -> void:
	#print("jumping")
	# Play jump animation corresponding to how far up and down we go
	var time: float = Helpers.map(body.velocity.y, jump_speed, -jump_speed, 0, 1, true)
	
	var total_frames: int = animated_sprite.sprite_frames.get_frame_count("jump")
	var frame_index = int(time * (total_frames - 1))
	animated_sprite.play("jump")
	animated_sprite.frame = frame_index
	
	#if grounded or (!grounded and !jumping) or dash_timer > 0 or bounce_timer > 0:
	if body.grounded or (!body.grounded and !jumping):
		is_complete = true
	return

func fixed_do() -> void:
	push_warning("_fixed_do not implemented")

func exit() -> void:
	jumping = false
