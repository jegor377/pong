extends Node2D

signal lose(side)
signal resume_game()

var lose_time = 3
var side_to_resume := 0

func _input(event):
	if event.is_action("ui_cancel"):
		get_tree().quit()

func _on_lose(side):
	lose_time = 3
	$WaitTime.text = str(lose_time)
	$WaitTime.show()
	side_to_resume = side
	start_lose_timer()
	$LoseSFX.play()
	
	if side_to_resume == 1: # right won
		$RightPoints.text = str(int($RightPoints.text) + 1)
	elif side_to_resume == -1: # left won
		$LeftPoints.text = str(int($LeftPoints.text) + 1)


func start_lose_timer() -> void:
	$Timer.start()

func _on_timer_timeout():
	lose_time -= 1
	$WaitTime.text = str(lose_time)
	if lose_time != 0:
		$Timer.start()
	else:
		emit_signal("resume_game")
		$WaitTime.hide()


func _on_resume_game():
	$Ball.emit_signal("reset", side_to_resume)


func _on_music_finished():
	$music.play()
