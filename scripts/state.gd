class_name State extends Node


# Timer isn't working...
var is_complete: bool
var start_time: float = Time.get_ticks_msec() / 1000.0
var time: float:
	get:
		return Time.get_ticks_msec() / 1000.0 - start_time

var body: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var input: InputComponent
var state_label: Label

@export var DEFAULT_GRAVITY := 400

func enter() -> void:
	push_warning("_enter not implemented")
	
func do(delta: float) -> void:
	push_warning("_do not implemented")

func physics_do(delta: float) -> void:
	push_warning("_fixed_do not implemented")

func exit() -> void:
	push_warning("_exit not implemented")
	
func setup(_body: CharacterBody2D, _animated_sprite: AnimatedSprite2D, _input: InputComponent, _state_label: Label) -> void:
	body = _body
	animated_sprite = _animated_sprite
	input = _input
	state_label = _state_label
	
func initialize() -> void:
	is_complete = false
	start_time = Time.get_ticks_msec() / 1000.0
	
func gravity() -> float:
	return DEFAULT_GRAVITY
	
