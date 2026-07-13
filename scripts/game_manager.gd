extends Node

var current_round_number = 1
var blue_team_score = 0
var gold_team_score = 0
var score
@onready var current_round = $"../CurrentRound"
@onready var score_label: Label = $ScoreLabel
@onready var fade_to_black = $CanvasLayer/FadeToBlackColorRect
@onready var round_end_ui = $CanvasLayer/RoundEndUI

@onready var gold_win_bar = $CanvasLayer/RoundEndUI/GoldWinBar/ActualWins
@onready var gold_win_icons = gold_win_bar.get_children()

@onready var blue_win_bar = $CanvasLayer/RoundEndUI/BlueWinBar/ActualWins
@onready var blue_win_icons = blue_win_bar.get_children()

@onready var round_label = $CanvasLayer/RoundStartUI/RoundNumberControl/RoundLabel
@onready var round_control = $CanvasLayer/RoundStartUI/RoundNumberControl
@onready var go_label = $CanvasLayer/RoundStartUI/GoWordControl/GoLabel
@onready var go_control = $CanvasLayer/RoundStartUI/GoWordControl
@onready var round_circle = $CanvasLayer/RoundStartUI/AnimatedSprite2D2
var round_control_pos
var go_control_pos


func _ready() -> void:
	round_end_ui.visible = false
	round_control_pos = round_control.position
	go_control_pos = go_control.position
	Global.snail_win.connect(round_win)
	Global.berry_win.connect(round_win)
	start_round()

func round_win(winning_team: String):
	if winning_team == "Blue":
		print("game manager says blue wins")
		blue_team_score += 1
	elif winning_team == "Gold":
		print("game manager says gold wins")
		gold_team_score += 1
		
	current_round_number += 1
		
	end_round()

#func update_score_label():
	#score_label.text = "Blue Team " + str(blue_team_score) + " \nGold Team " + str(gold_team_score)
	
	

func slam_label(label: Label):
	label.modulate.a = 0.0
	
	var curr_scale = label.scale 
	label.scale = curr_scale * 0.25

	var tween = create_tween()

	# Fade in and grow past the final size.
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.25)
	tween.tween_property(label, "scale", curr_scale * 1.6, 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	## Then settle back to the normal size.
	tween.set_parallel(false)
	tween.tween_property(label, "scale", curr_scale, 0.12)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

func start_round():
	# Set up UI to play again. Useful for 2nd round and onwards	
	round_label.text = "Round %s" % current_round_number	
	go_label.modulate.a = 0.0
	go_control.position = go_control_pos
	round_label.modulate.a = 0.0
	round_control.position = round_control_pos
	round_circle.modulate.a = 1.0
	
	# Play expanding circle animation and fade in Round Label. Then wait 
	round_circle.play("default")
	var tween = create_tween()
	tween.tween_property(round_label, "modulate:a", 1.0, 0.7)
	await get_tree().create_timer(1.2).timeout
	
	# Slam Go label and wait
	slam_label(go_label)
	await get_tree().create_timer(0.7).timeout
	
	# Make labels scatter left and right and fade out circle. Then start the round
	var round_tween = create_tween()
	round_tween.set_trans(Tween.TRANS_QUAD)
	round_tween.set_ease(Tween.EASE_IN_OUT)
	var go_tween = create_tween()
	go_tween.set_trans(Tween.TRANS_QUAD)
	go_tween.set_ease(Tween.EASE_IN_OUT)
	
	round_tween.tween_property(
		round_control,
		"position",
		round_control.position + Vector2(-2000, 0),
		0.8
	)

	go_tween.tween_property(
		go_control,
		"position",
		go_control.position + Vector2(2000, 0),
		0.8
	)
	
	var round_circle_tween = create_tween()
	round_circle_tween.tween_property(round_circle, "modulate:a", 0.0, 0.3)
	
	Global.game_state = Global.GameState.PLAYING
	

func end_round():
	# Turn off player input
	Global.game_state = Global.GameState.BETWEEN_ROUNDS

	# Load new Round immeditately
	var new_round = preload("res://scenes/current_round.tscn").instantiate()
	new_round.name = "CurrentRound"

	# Fade to dim
	fade_to_black.color = Color.BLACK
	fade_to_black.modulate = Color(1, 1, 1, 0)
	var tween_darken = create_tween()
	tween_darken.tween_property(fade_to_black, "modulate:a", 0.75, 0.4)
	
	# Display current score and wait a bit
	round_end_ui.visible = true
	round_end_ui.modulate.a = 0.0
	var tween_show_ui = create_tween()
	tween_show_ui.tween_property(round_end_ui, "modulate:a", 1.0, 0.4)
	await get_tree().create_timer(1.1).timeout
	
	#Update Score
	for i in gold_win_icons.size():
		if i < gold_team_score:
			gold_win_icons[i].visible = true
	for i in blue_win_icons.size():
		if i < blue_team_score:
			blue_win_icons[i].visible = true
	await get_tree().create_timer(1.75).timeout
		
	# Delete current round and instantiate new one
	current_round.queue_free()
	add_child(new_round)
	current_round = new_round
	
	# Turn off score UI
	round_end_ui.visible = false
	fade_to_black.modulate.a = 0.0
	
	start_round()
