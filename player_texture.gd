extends TextureRect

@onready
var tree := get_tree()

func enable() -> void:
	var tween = tree.create_tween()
	tween.tween_property(self, "modulate", Color(Color.WHITE, 1), 0.1)

func disable() -> void:
	var tween = tree.create_tween()
	tween.tween_property(self, "modulate", Color(Color.WHITE, 0.1), 0.1)
