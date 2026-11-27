extends Node2D

@export var disco_ball_sound: AudioStream

const SPEED = 20

var sprite: AnimatedSprite2D
var direction = 1
var player_near = false
var audio_stream: AudioStreamPlayer2D
var fade_tween: Tween

func _ready():
	sprite = $AnimatedSprite2D
	$OnSnailCheck.body_entered.connect(_player_rides_snail)
	$OnSnailCheck.body_exited.connect(_player_leaves_snail)
	$CrossFinishLineCheck.area_entered.connect(_snail_crossed_finish_line)
	sprite.play("idle")
	audio_stream = AudioStreamPlayer2D.new()
	add_child(audio_stream)
	audio_stream.bus = "Reverb"

func _player_rides_snail(body):
	if body.is_in_group("Player"):
		#print("player near")
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
	
#func start_moving_sound():
	#if fade_tween:
		#fade_tween.kill()
		#fade_tween = null
#
	#audio_stream.volume_db = -18.0
#
	#if !audio_stream.playing:
		#Global.play_sound(audio_stream, disco_ball_sound, -18.0, 0.0, 0.0)
		
#func stop_moving_sound():
	#if fade_tween:
		#fade_tween.kill()
#
	#fade_tween = create_tween()
	#fade_tween.tween_property(audio_stream, "volume_db", -80.0, 0.1)
	#fade_tween.tween_callback(audio_stream.stop)

func _physics_process(delta):
	var blue_count = 0
	var gold_count = 0
	var moving = false

	for body in $OnSnailCheck.get_overlapping_bodies():
		if body.is_in_group("Player") and body.is_in_group("Blue"):
			blue_count += 1
		elif body.is_in_group("Player") and body.is_in_group("Gold"):
			gold_count += 1

	if blue_count > gold_count:
		sprite.play("moving")
		direction = -1
		moving = true
		#sprite.flip_h = true
	elif gold_count > blue_count:
		sprite.play("moving")
		moving = true
		direction = 1
		#sprite.flip_h = false
	else:
		sprite.play("idle")
		moving = false
		direction = 0
	
	if moving:
		if !audio_stream.playing:
			Global.play_sound(audio_stream, disco_ball_sound, -18.0, 0.0, 0.0)
	else:
		if audio_stream.playing:
			audio_stream.stop()
	
	position.x += direction * SPEED * delta
