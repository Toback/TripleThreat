extends Light2D

@export var light_name: String
@onready var wrap_bounds: ReferenceRect = get_tree().get_first_node_in_group("WrapBounds")

func _ready()->void:
	visible = true
	if light_name.contains("LEFT"):
		position.x = -wrap_bounds.size.x
	if light_name.contains("RIGHT"):
		position.x = wrap_bounds.size.x
	if light_name.contains("UP"):
		position.y = -wrap_bounds.size.y
	if light_name.contains("DOWN"):
		position.y = wrap_bounds.size.y
