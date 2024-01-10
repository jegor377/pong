extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	if Networking.session_role == Networking.ClientType.MAIN:
		%FirstPlayerLabel.text += " (You)"
		%SecondPlayerLabel.text += " (Enemy)"
	elif Networking.session_role == Networking.ClientType.SECONDARY:
		%SecondPlayerLabel.text += " (You)"
		%FirstPlayerLabel.text += " (Enemy)"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
