extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	animation_player.play("pickup")
	# Check if the body has the function we want to call
	if body.has_method("transformIntoWarrior"):
		body.call_deferred("transformIntoWarrior")
