extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var state: int = 0

var berry_hole_unfilled: Texture2D = preload("res://assets/sprites/BerryHoleUnfilled.png")
var berry_hole_filled: Texture2D = preload("res://assets/sprites/BerryHolefilled.png")


var berry_hold_states = [berry_hole_unfilled, berry_hole_filled]

func _ready() -> void:
	sprite.texture = berry_hold_states[0]

func _on_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("Player") and state == 0:
		if _body.has_berry:
			state = 1
			sprite.texture = berry_hold_states[state]
			_body.has_berry = false
	
