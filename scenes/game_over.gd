extends CanvasLayer

signal restart

const FADE_TIME := 1.5

func show_game_over():
	show()
	$GameOverImage.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property($GameOverImage, "modulate:a", 1.0, FADE_TIME)

func _on_restart_button_pressed():
	restart.emit()
