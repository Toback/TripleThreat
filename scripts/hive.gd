extends Node

var total_berries: int
var team: String
var scored_berries: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.score_berry.connect(_process_score_berry)
	total_berries = get_child_count()
	if is_in_group("Blue"):
		team = "Blue"
	elif is_in_group("Gold"):
		team = "Gold" 
	print(team + " " + str(total_berries))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process_score_berry(scoring_team):
	if scoring_team == team:
		scored_berries += 1
		if total_berries == scored_berries:
			Global.berry_win.emit(team)
