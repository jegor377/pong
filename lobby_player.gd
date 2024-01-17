extends VBoxContainer

@export
var player_name := ""

var role := ""

func _ready() -> void:
	update_label()

func set_as_you() -> void:
	role = "(you)"
	update_label()

func set_as_enemy() -> void:
	role = "(enemy)"
	update_label()

func set_as_noone() -> void:
	role = ""
	update_label()

func update_label() -> void:
	$Label.text = player_name + " " + role
	
func set_ready(is_ready: bool) -> void:
	if is_ready:
		$VBoxContainer/Icon.enable()
	else:
		$VBoxContainer/Icon.disable()
