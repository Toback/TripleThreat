extends Node2D

const SPEED = 20

@onready var sprite: Sprite2D = $Sprite2D

var direction = 1
var player_near = false

func _ready():
	$OnSnailCheck.body_entered.connect(_player_rides_snail)
	$OnSnailCheck.body_exited.connect(_player_leaves_snail)
	$CrossFinishLineCheck.area_entered.connect(_snail_crossed_finish_line)

func _player_rides_snail(body):
	if body.is_in_group("Player"):
		print("player near")
		player_near = true
		
	if body.is_in_group("Net"):
		print("Finish!222!")
		return

func _player_leaves_snail(body):
	if body.is_in_group("Player"):
		player_near = false
		
func _snail_crossed_finish_line(area):
	if area.is_in_group("Net"):
		if area.is_in_group("Blue"):
			Global.snail_win.emit("Blue")
		elif area.is_in_group("Gold"):
			Global.snail_win.emit("Gold")

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
