extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var state: int = 0

var berry_pile_unfilled: Texture2D = preload("res://assets/sprites/BerryPilUnfull.png")
var berry_pile_filled: Texture2D = preload("res://assets/sprites/BerryPillFull.png")

var berry_pile_states = [berry_pile_filled, berry_pile_unfilled,]

func _ready() -> void:
	sprite.texture = berry_pile_states[0]

func _on_body_entered(body: Node2D) -> void:
	# Check if the body has the function we want to call
	if body.is_in_group("Player") and state == 0:
		if body.has_berry==false:
			body.has_berry=true
			state = 1
			sprite.texture = berry_pile_states[state]
		
