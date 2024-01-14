extends CharacterBody2D


const SPEED = 500.0
const AI_SLOW = 100

@export
var side: Networking.ClientType = Networking.ClientType.NONE

@export
var bounce_offset: Vector2

@onready
var initial_x = position.x

func _physics_process(delta):
	if Networking.session_role == side:
		var direction = Input.get_axis("ui_up", "ui_down")
		if direction and (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down")):
			velocity.y = direction * SPEED
		else:
			velocity.y = 0
	else:
		# when commented, it works better
		# velocity.y = Networking.enemy_dir.y * SPEED
		position.y = Networking.enemy_pos.y

	position.x = initial_x
	move_and_slide()
	if Networking.session_role == side:
		Networking.set_pallete_pos(position, velocity.normalized())
