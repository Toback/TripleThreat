
class_name Award extends CharacterBody2D

@export var gravity: float = 900.0
@export var throw_speed: float = 350.0
@export var carry_offset: Vector2 = Vector2(0, -19)
@export var crouch_carry_offset: Vector2 = Vector2(0, -12)

var is_held: bool = false
var holder: CharacterBody2D = null
var active: bool = true


func _physics_process(delta: float) -> void:
	if is_held:
		if is_instance_valid(holder):
			if holder.crouch_state.state_label.text == "crouch":
				global_position = holder.global_position + crouch_carry_offset
			else:
				global_position = holder.global_position + carry_offset

	
	
	if is_held:
		return

	velocity.y += gravity * delta
	move_and_slide()


func pick_up(player: CharacterBody2D) -> void:
	is_held = true
	holder = player
	player.has_berry = true
	player.award = self
	active = false
	velocity = Vector2.ZERO

	# Disable collisions while carried.
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Position the object above the ground.
	global_position = holder.global_position + carry_offset


func throw(direction: Vector2) -> void:
	is_held = false
	holder = null
	active = true

	# Re-enable collisions.
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

	# Give the object an initial throwing velocity.
	velocity = direction.normalized() * throw_speed


func _on_pick_up_area_2d_body_entered(body: Node2D) -> void:
	# Check if the body has the function we want to call
	if body.is_in_group("Player") and active:
		print(body.has_berry, " ", body.award)
		if body.has_berry==false and !is_instance_valid(body.award):
			pick_up(body)
