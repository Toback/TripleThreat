extends Node2D

const SEGMENTS := 5
var hair_positions: Array = []
var hair_sizes: Array = []
@onready var warrior_component_state_machine: CharacterBody2D = $"../WarriorTowerfall"

@export var head_offset: Vector2 = Vector2(0, -12) # adjust where hair attaches
@export var chase_speed := 2
@export var base_size := 10

func _ready():
	# initialize hair segments at player position
	for i in range(SEGMENTS):
		hair_positions.append(warrior_component_state_machine.global_position + head_offset)
		hair_sizes.append(base_size - i)

func _process(_delta: float) -> void:
	update_hair()

func update_hair():
	var last = warrior_component_state_machine.global_position + head_offset
	
	for i in range(SEGMENTS):
		var pos = hair_positions[i]
		pos.x += (last.x - pos.x) / chase_speed
		pos.y += (last.y - pos.y) / chase_speed
		hair_positions[i] = pos

		# update "last" for the next segment
		last = pos
	
	queue_redraw()

func _draw():
	var color
	if warrior_component_state_machine.dash_state.can_dash:
		color = Color(1, 0, 1) # magenta/pink
	else:
		color = Color(1, 0, 0)
	for i in range(SEGMENTS):
		draw_circle(hair_positions[i], hair_sizes[i], color)
