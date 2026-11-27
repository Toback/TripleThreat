extends Node2D

enum GameState {
	PLAYING,
	BETWEEN_ROUNDS
}

var score = 0
var game_state = GameState.BETWEEN_ROUNDS

const TIME_UNTIL_DESTROYED = 0.5
@warning_ignore("unused_signal") signal snail_win(team: String)
@warning_ignore("unused_signal") signal berry_win(team: String)
@warning_ignore("unused_signal") signal score_berry(team: String)

func play_sound(player: AudioStreamPlayer2D, sound: AudioStream, volume_db: float = 0.0, random_offset: float = 0.0, offset: float = 0.0) -> void:
	player.stream = sound
	player.volume_db =volume_db
	player.pitch_scale = randf_range(1.0 + offset - random_offset, 1.0 + offset + random_offset)
	player.play()
