extends Control

@export
var lobby_scene: PackedScene

var IPRegEx = RegEx.new()
var action := "none"

# Called when the node enters the scene tree for the first time.
func _ready():
	IPRegEx.compile("^\\d{0,3}\\.\\d{0,3}\\.\\d{0,3}\\.\\d{0,3}$")
	Networking.ip = %IPEdit.text
	Networking.port = %PortEdit.text
	Networking.connect("connected", _on_connected)
	Networking.connect("not_connected", _on_not_connected)
	Networking.connect("assigned_to_session", _on_assigned_to_session)
	Networking.connect("could_not_create_session", _on_could_not_create_session)
	Networking.connect("could_not_assign_to_session", _on_could_not_assign_to_session)


func _on_connect_pressed():
	action = "join"
	if not Networking.is_connected_to_server():
		set_btns_disabled(true)
		Networking.connect_to_server()
	%JoinMenu.visible = true


func _on_host_pressed():
	action = "host"
	if not Networking.is_connected_to_server():
		set_btns_disabled(true)
		Networking.connect_to_server()
	else:
		_on_connected()


func set_btns_disabled(state) -> void:
	%Join.disabled = state
	%Host.disabled = state

@onready var old_ip: String = %IPEdit.text
func _on_ip_edit_text_changed(new_text):
	if IPRegEx.search(new_text):
		Networking.ip = new_text
		old_ip = new_text
	else:
		%IPEdit.text = old_ip


@onready var old_port: String = %PortEdit.text
func _on_port_edit_text_changed(new_text: String):
	if new_text.is_valid_int() or new_text == '':
		Networking.port = new_text
		old_port = new_text
	else:
		%PortEdit.text = old_port

func _on_connected() -> void:
	set_btns_disabled(false)
	if action == "join":
		pass
	elif action == "host":
		Networking.create_session()
	
func _on_not_connected() -> void:
	set_btns_disabled(false)
	print("NOT_CONNECTED")

func _on_assigned_to_session(client_id: int, role: int) -> void:
	get_tree().change_scene_to_packed(lobby_scene)

func _on_could_not_create_session() -> void:
	%ErrorMsg.text = "Could not create session"
	%Errors.visible = true

func _on_back_btn_pressed():
	%JoinMenu.visible = false

func _on_join_btn_pressed():
	print("Connecting to session with id: ", %SessionId.value)
	Networking.join_session(%SessionId.value)

func _on_could_not_assign_to_session(session_id: int) -> void:
	%ErrorMsg.text = "Could not assign to session with id: " + str(session_id)
	%Errors.visible = true


func _on_close_error_msg_pressed():
	%Errors.visible = false
