extends Control

func _ready():
	$ThemeMusic.finished.connect($ThemeMusic.play)
	AudioManager.register_music_player($ThemeMusic)
	update_mute_button()

func update_mute_button():
	$MuteButton.text = "Unmute" if AudioManager.is_music_muted() else "Mute"

func _on_mute_button_pressed():
	AudioManager.toggle_music_mute()
	update_mute_button()

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
