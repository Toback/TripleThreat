class_name State extends Node

var is_complete: bool
var start_time: float = Time.get_ticks_msec() / 1000.0
var time: float:
	get:
		return Time.get_ticks_msec() / 1000.0 - start_time

var body: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var input: InputComponent
var audio_streams: Array[AudioStreamPlayer2D]
var state_label: Label

@export var DEFAULT_GRAVITY := 400

func enter() -> void:
	push_warning("_enter not implemented")
	
func do(_delta: float) -> void:
	push_warning("_do not implemented")

func physics_do(_delta: float) -> void:
	push_warning("_fixed_do not implemented")

func exit() -> void:
	push_warning("_exit not implemented")
	
func setup(_body: CharacterBody2D, _animated_sprite: AnimatedSprite2D, _input: InputComponent, _state_label: Label, _audio_streams: Array[AudioStreamPlayer2D]) -> void:
	body = _body
	animated_sprite = _animated_sprite
	input = _input
	state_label = _state_label
	audio_streams = _audio_streams
	
func play_sound(sound: AudioStream, volume_db: float = 0.0, random_offset: float = 0.0, offset: float = 0.0) -> void:
	audio_streams[body.audio_index].stream = sound
	audio_streams[body.audio_index].volume_db = volume_db
	audio_streams[body.audio_index].pitch_scale = randf_range(1.0 + offset - random_offset, 1.0 + offset + random_offset)
	audio_streams[body.audio_index].play()
	
	body.audio_index = (body.audio_index + 1) % audio_streams.size()
	
func stop_sound()-> void:
	audio_streams[(body.audio_index - 1) % audio_streams.size()].stop()
	
func initialize() -> void:
	is_complete = false
	start_time = Time.get_ticks_msec() / 1000.0
	
func gravity() -> float:
	return DEFAULT_GRAVITY
	
