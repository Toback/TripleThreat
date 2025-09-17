extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var state: int = 0

var neutral_gate: Texture2D = preload("res://assets/sprites/WarriorGate.png")
var blue_gate: Texture2D = preload("res://assets/sprites/BWarriorGate.png")
var gold_gate: Texture2D = preload("res://assets/sprites/GWarriorGate.png")

var gates = [neutral_gate, blue_gate, gold_gate]

func _ready() -> void:
	sprite.texture = gates[0]
	print('gate is ready')
	
	# body_entered.connect(_on_enter)
	# body_exited.connect(_on_exit)

# aaasfunc _on_enter(body: Node) -> void:
#	if body.is_in_group("Player"):  # optional extra safety

#func _on_exit(body: Node) -> void:
	#if body.is_in_group("Player"):
		#close_gate()


func _on_body_entered(body: Node2D) -> void:
	print("entered gate")
	state = (state + 1) % len(gates)
	
	sprite.texture = gates[state]
