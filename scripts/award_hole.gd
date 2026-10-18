extends Area2D
var team: String

@onready var unfilled: Sprite2D = $UnfilledSlot
@onready var filled: Sprite2D = $FilledSlot

func _ready() -> void:
	filled.visible = false
	unfilled.visible = true
	if is_in_group("Blue"):
		team = "Blue"
	elif is_in_group("Gold"):
		team = "Gold"

func _on_body_entered(_body: Node2D) -> void:
	if _body.is_in_group("Player") and _body.is_in_group(team) and unfilled.visible:
		if _body.has_berry:
			filled.visible = true
			unfilled.visible = false
			_body.has_berry = false
			_body.award.visible = false
			_body.award.active = false
			_body.award = null
			Global.score_berry.emit(team)
				
