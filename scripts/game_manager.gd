extends Node

var blue_team_score = 0
var gold_team_score = 0
var score
@onready var current_round = $"../CurrentRound"
@onready var score_label: Label = $ScoreLabel
@onready var fade = $CanvasLayer/ColorRect

func _ready() -> void:
	Global.snail_win.connect(round_win)

func round_win(winning_team: String):
	if winning_team == "Blue":
		print("game manager says blue wins")
		blue_team_score += 1
	elif winning_team == "Gold":
		print("game manager says gold wins")
		gold_team_score += 1
	
	update_score_label()
	
	end_round()

func update_score_label():
	score_label.text = "Blue Team " + str(blue_team_score) + " \nGold Team " + str(gold_team_score)
	
func end_round():
	fade.color = Color.BLACK
	fade.modulate = Color(1, 1, 1, 0)
	var tween_darken = create_tween()
	tween_darken.tween_property(fade, "modulate:a", 1.0, 0.5)

	current_round.queue_free()
	var new_round = preload("res://scenes/current_round.tscn").instantiate()
	new_round.name = "CurrentRound"
	await tween_darken.finished

	#await get_tree().create_timer(5.0).timeout

	add_child(new_round)
	current_round = new_round
	
	var tween_lighten = create_tween()
	tween_lighten.tween_property(fade, "modulate:a", 0.0, 0.5)
