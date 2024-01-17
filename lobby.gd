extends Control

@onready
var tree := get_tree()

# Called when the node enters the scene tree for the first time.
func _ready():
	%LobbyName.text = "Lobby #" + str(Networking.session_id)
	if Networking.session_role == Networking.ClientType.MAIN:
		%LeftPlayer.set_as_you()
		%RightPlayer.set_as_enemy()
	elif Networking.session_role == Networking.ClientType.SECONDARY:
		%LeftPlayer.set_as_enemy()
		%RightPlayer.set_as_you()
	
	Networking.connect("disconnected", _on_disconnected)
	Networking.connect("session_leave_status", _on_session_leave_status)
	Networking.connect("became_main", _on_became_main)
	Networking.connect("assigned_to_session", _on_assigned_to_session)
	Networking.connect("set_ready", _on_set_ready)
	Networking.connect("game_started", _on_game_started)


func _on_disconnected() -> void:
	tree.change_scene_to_file("res://menu.tscn")


func _on_back_btn_pressed():
	Networking.leave_session()
	

func _on_session_leave_status(client_id, left) -> void:
	if client_id == Networking.current_id and left:
		print("Left session")
		tree.change_scene_to_file("res://menu.tscn")
	else:
		%RightPlayer.set_as_noone()

func _on_became_main() -> void:
	print("Became main")
	%LeftPlayer.set_as_you()
	%RightPlayer.set_as_noone()

func _on_assigned_to_session(client_id: int, role: int) -> void:
	if Networking.current_id != client_id: # is not me
		if role == Networking.ClientType.SECONDARY:
			%RightPlayer.set_as_enemy()

func _on_set_ready(client_type, readiness) -> void:
	match client_type:
		Networking.ClientType.MAIN:
			%LeftPlayer.set_ready(readiness)
		Networking.ClientType.SECONDARY:
			%RightPlayer.set_ready(readiness)

func _on_ready_btn_pressed():
	var current_readiness := Networking.current_ready
	Networking.set_readiness(not current_readiness)

func _on_game_started() -> void:
	tree.change_scene_to_file("res://game.tscn")
