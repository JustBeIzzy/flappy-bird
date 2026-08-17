extends Node

const MUTED_DB := -80.0

var muted := false
var music_player : AudioStreamPlayer = null

func register_music_player(player: AudioStreamPlayer):
	music_player = player
	player.volume_db = MUTED_DB if muted else 0.0

func toggle_music_mute() -> bool:
	muted = not muted
	if music_player:
		music_player.volume_db = MUTED_DB if muted else 0.0
	return muted

func is_music_muted() -> bool:
	return muted
