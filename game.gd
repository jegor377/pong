extends Node2D

signal lose(side)
signal resume_game()

var lose_time = 3
var side_to_resume := 0

@onready
var tree = get_tree()

func _ready() -> void:
	Networking.connect("session_leave_status", _on_session_leave_status)
	Networking.connect("point_scored", _on_point_scored)

func _input(event):
	if event.is_action("ui_cancel"):
		Networking.leave_session()
		tree.change_scene_to_file("res://menu.tscn")

func _on_lose(side):
	if Networking.session_role == Networking.ClientType.MAIN:
		match int(side):
			-1:
				Networking.say_point_scored(Networking.ClientType.MAIN)
			1:
				Networking.say_point_scored(Networking.ClientType.SECONDARY)

func _on_point_scored() -> void:
	lose_time = 3
	$WaitTime.text = str(lose_time)
	$WaitTime.show()
	var side: float
	match Networking.client_type_scored:
		Networking.ClientType.MAIN:
			side = -1
		Networking.ClientType.SECONDARY:
			side = 1
	side_to_resume = side
	start_lose_timer()
	$LoseSFX.play()
	
	$LeftPoints.text = str(Networking.main_score)
	$RightPoints.text = str(Networking.secondary_score)

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

func _on_session_leave_status(_client_id, _left) -> void:
	Networking.leave_session()
	tree.change_scene_to_file("res://menu.tscn")
