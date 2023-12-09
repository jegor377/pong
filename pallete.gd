extends CharacterBody2D


const SPEED = 500.0
const AI_SLOW = 100

@export
var follow_node_path: NodePath

@export
var bounce_offset: Vector2

@onready
var initial_x = position.x

var follow_node = null

func _physics_process(delta):
	if follow_node_path.is_empty():
		var direction = Input.get_axis("ui_up", "ui_down")
		if direction and (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")):
			velocity.y = direction * SPEED
		else:
			velocity.y = 0
		position.x = initial_x
	else:
		if follow_node == null:
			follow_node = get_node(follow_node_path)
		
		var abs_dist = abs(follow_node.position.y - position.y)
		if abs_dist > 60:
			if position.y < follow_node.position.y:
				velocity.y = SPEED - AI_SLOW
			else:
				velocity.y = -SPEED + AI_SLOW
		else:
			velocity.y = 0
		position.x = initial_x

	move_and_slide()
