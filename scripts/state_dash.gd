class_name DashState extends State

@export var DASH_SPEED := 400.0
@export var DASH_TIME := 0.3
var dash_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

func current_facing_direction() -> Vector2:
	if animated_sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT

func enter() -> void:
	print("dash")
	dash_timer = DASH_TIME
	dash_dir = Helpers.get_snapped_direction(input.get_movement_direction(body.PLAYER_ID))
	if dash_dir == Vector2.ZERO:
		dash_dir = current_facing_direction()
	state_label.text = "dashing"

	
func do(delta: float) -> void:
	dash_timer = max(DASH_TIME - time, 0)
	if dash_timer == 0:
		is_complete = true
	return

func physics_do(delta: float) -> void:
	body.freeVelocity.y += gravity() * delta
	body.freeVelocity = dash_dir * DASH_SPEED

func exit() -> void:
	dash_timer = 0.0
	
func gravity() -> float:
	return 0.0
