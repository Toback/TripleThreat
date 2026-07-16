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
