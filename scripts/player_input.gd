class_name InputComponent extends Node

func get_movement_direction() -> Vector2:
	#MultiplayerInput.get_vector(PLAYER_ID, "move_left", "move_right", "move_up", "move_down")
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func wants_jump() -> bool:
	#MultiplayerInput.is_action_just_pressed(PLAYER_ID,"jump")
	#MultiplayerInput.is_action_pressed(PLAYER_ID, "jump")
	return Input.is_action_pressed("jump")
	
func wants_flap() -> bool:
	#MultiplayerInput.is_action_just_pressed(PLAYER_ID,"jump")
	#MultiplayerInput.is_action_pressed(PLAYER_ID, "jump")
	return Input.is_action_just_pressed("jump")
	
func wants_dash() -> bool:
	#MultiplayerInput.is_action_just_pressed(PLAYER_ID, "dash") and canDash:
	return Input.is_action_just_pressed('dash')
	
