extends Area2D

@export
var side: int = 0

func _on_body_entered(body):
	if body.is_in_group("ball"):
		get_parent().emit_signal("lose", side)
