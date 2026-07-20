extends Node2D

var starting_scale: Vector2
@export var sprite: AnimatedSprite2D
var flipped: bool
@onready var wrap_bounds: ReferenceRect = get_tree().get_first_node_in_group("WrapBounds")

func _ready()->void:
	starting_scale = sprite.scale
	
func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(
		sprite.animation,
		sprite.frame
	)
	
	# Get facing direction on anim correct	
	scale.x = starting_scale.x * (-1.0 if sprite.flip_h else 1.0)

	
	var offset: Vector2 = -texture.get_size() / 2

	# Horizontal ghosts
	draw_texture(texture, offset + Vector2(wrap_bounds.size.x, 0))
	draw_texture(texture, offset + Vector2(-wrap_bounds.size.x, 0))
	
	# Vertical ghosts
	draw_texture(texture, offset + Vector2(0, wrap_bounds.size.y))
	draw_texture(texture, offset + Vector2(0, -wrap_bounds.size.y))
	
	# Diagonal Ghosts
	draw_texture(texture, offset + Vector2(wrap_bounds.size.x, wrap_bounds.size.y))
	draw_texture(texture, offset + Vector2(-wrap_bounds.size.x, wrap_bounds.size.y))
	draw_texture(texture, offset + Vector2(wrap_bounds.size.x, -wrap_bounds.size.y))
	draw_texture(texture, offset + Vector2(-wrap_bounds.size.x, -wrap_bounds.size.y))
