extends Node2D

const SPEED = 20

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var sprite: Sprite2D = $Sprite2D

var direction = 1
var player_near = false

func _ready():
	$OnSnailCheck.body_entered.connect(_on_body_entered)
	$OnSnailCheck.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		print("player near")
		player_near = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_near = false

func _physics_process(delta):
	var blue_count = 0
	var gold_count = 0

	for body in $OnSnailCheck.get_overlapping_bodies():
		if body.is_in_group("Player") and body.is_in_group("Blue"):
			blue_count += 1
		elif body.is_in_group("Player") and body.is_in_group("Gold"):
			gold_count += 1

	if blue_count > gold_count:
		direction = -1
		sprite.flip_h = true
	elif gold_count > blue_count:
		direction = 1
		sprite.flip_h = false
	else:
		direction = 0
	
	position.x += direction * SPEED * delta
