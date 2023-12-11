extends Control


var IPRegEx = RegEx.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	IPRegEx.compile("^\\d{0,3}\\.\\d{0,3}\\.\\d{0,3}\\.\\d{0,3}$")
	Networking.ip = %IPEdit.text
	Networking.port = %PortEdit.text


func _on_connect_pressed():
	Networking.connect_to_server()


func _on_host_pressed():
	pass # Replace with function body.


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
