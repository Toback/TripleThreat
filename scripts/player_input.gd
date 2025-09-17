class_name InputComponent extends Node

func get_movement_direction(player_id: int) -> Vector2:
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		return Input.get_vector("move_left", "move_right", "move_up", "move_down")
	else:
		return MultiplayerInput.get_vector(player_id, "move_left", "move_right", "move_up", "move_down")
	#MultiplayerInput.get_vector(PLAYER_ID, "move_left", "move_right", "move_up", "move_down")

func wants_jump(player_id: int) -> bool:
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		return Input.is_action_pressed("jump")
	else:
		return MultiplayerInput.is_action_pressed(player_id,"jump")
	
	
func wants_flap(player_id: int) -> bool:
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		return Input.is_action_just_pressed("jump")
	else:
		return MultiplayerInput.is_action_just_pressed(player_id,"jump")
	
func wants_dash(player_id: int) -> bool:
	if not Input.get_joy_name(0) or not Input.get_joy_name(1):
		return Input.is_action_just_pressed("dash")
	else:
		return MultiplayerInput.is_action_just_pressed(player_id, "dash")
	
