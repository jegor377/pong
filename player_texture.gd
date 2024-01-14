extends TextureRect


func enable() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(Color.WHITE, 1), 0.1)

func disable() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(Color.WHITE, 0.1), 0.1)
