extends Node2D

const SEGMENTS := 5
var hair_positions: Array = []
var hair_sizes: Array = []
@onready var warrior_component_state_machine: CharacterBody2D = $".."

@export var head_offset: Vector2 = Vector2(0, -6) # adjust where hair attaches
@export var chase_speed := 1.5
@export var base_size := 10

func _ready():
	# initialize hair segments at player position
	for i in range(SEGMENTS):
		hair_positions.append(Vector2.ZERO)
		hair_sizes.append(base_size - i)


func update_hair(player_pos: Vector2, facing: int):
	# first "target" is just behind the player’s head
	var last = Vector2.ZERO
	#+ head_offset + Vector2(4 - facing * 2, 3)

	for i in range(SEGMENTS):
		var pos = hair_positions[i]
		pos.x += (last.x - pos.x) / chase_speed
		pos.y += (last.y - pos.y) / chase_speed
		hair_positions[i] = pos

		# update "last" for the next segment
		last = pos
		
	queue_redraw()

func _draw():
	# Example: fixed color (you can animate based on state like Celeste)
	print("drawing")
	var color = Color(1, 0, 1) # magenta/pink
	for i in range(SEGMENTS):
		draw_circle(hair_positions[i], hair_sizes[i], color)
