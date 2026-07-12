extends Node

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

func _ready() -> void:
	round_end_ui.visible = false
	Global.snail_win.connect(round_win)
	Global.berry_win.connect(round_win)

func round_win(winning_team: String):
	if winning_team == "Blue":
		print("game manager says blue wins")
		blue_team_score += 1
	elif winning_team == "Gold":
		print("game manager says gold wins")
		gold_team_score += 1
		
	end_round()

#func update_score_label():
	#score_label.text = "Blue Team " + str(blue_team_score) + " \nGold Team " + str(gold_team_score)
	
	

func end_round():
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
