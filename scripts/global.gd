extends Node2D

enum GameState {
	PLAYING,
	BETWEEN_ROUNDS
}

var score = 0
var game_state = GameState.BETWEEN_ROUNDS

const TIME_UNTIL_DESTROYED = 0.5
signal snail_win(team: String)
signal berry_win(team: String)
signal score_berry(team: String)
