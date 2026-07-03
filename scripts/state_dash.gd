class_name DashState extends State

@export var DASH_SPEED := 400.0
@export var CROUCH_DASH_SPEED := 550.0
@export var DASH_TIME := 0.125
@export var DASH_COOLDOWN := 0.2
@export var DASH_COYOTE_TIME := 0.2
var dash_timer: float = 0.0
var dash_coyote_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO
var can_dash: bool = true
var dashed_from_ground: bool
var dashed_from_crouch: bool


func current_facing_direction() -> Vector2:
	if animated_sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT

func enter() -> void:
	print("dash")
	dash_timer = DASH_TIME
	dash_dir = Helpers.get_snapped_direction(input.get_movement_direction(body.PLAYER_ID))
	body.dash_cooldown_timer = DASH_COOLDOWN
	can_dash = false
	if dash_dir == Vector2.ZERO:
		dash_dir = current_facing_direction()
	if dashed_from_ground:
		body.dash_coyote_timer = DASH_COYOTE_TIME
	_dash()
	state_label.text = "dashing"

	
func do(_delta: float) -> void:
	dash_timer = max(DASH_TIME - time, 0)
	if dash_timer == 0:
		is_complete = true
	return

func physics_do(delta: float) -> void:
	body.freeVelocity.y += gravity() * delta

func _dash() -> void:
	var before_dash_speed = body.freeVelocity
	var new_speed: Vector2
	print("dash_dir", dash_dir)
	if dashed_from_crouch: #or (!dashed_from_ground and body.grounded):
		#new_speed = (current_facing_direction() * CROUCH_DASH_SPEED) + Vector2(body.velocity.x, 0)
		new_speed = current_facing_direction() * CROUCH_DASH_SPEED
	else:
		# Dashing from air is a bigger boost to make it feel better.
		if dashed_from_ground == false and dash_dir.y < 0:
			new_speed = dash_dir * DASH_SPEED * 1.05
		else:
			new_speed = dash_dir * DASH_SPEED
		#new_speed = (dash_dir * DASH_SPEED) + Vector2(abs(body.velocity.x)*sign(dash_dir.x),
															  #abs(body.velocity.x)*sign(dash_dir.y))                         #+ Vector2(body.velocity.x, 0)
	
	if (sign(before_dash_speed.x) == sign(new_speed.x) && abs(before_dash_speed.x) > abs(new_speed.x)):
		new_speed.x = before_dash_speed.x
	body.freeVelocity = new_speed
	

func exit() -> void:
	dash_timer = 0.0
	dashed_from_crouch = false
	dashed_from_ground = false
	
func gravity() -> float:
	return 0.0
