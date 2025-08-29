extends Node

var score = 0
@onready var score_label: Label = $ScoreLabel

func update_score():
	score += 1
	score_label.text = "Collected " + str(score) + " Coins"
	print(score)
