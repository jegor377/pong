extends CharacterBody2D

signal reset(side)

const SPEED = 700.0

var dir: Vector2 = Vector2.RIGHT

@onready
var initial_pos = position

var can_receive_ball_pos := true

func _physics_process(delta):
	if Networking.is_main():
		Networking.set_ball_pos(position, dir)
	elif can_receive_ball_pos:
		dir = Networking.ball_dir
		position = Networking.ball_pos
		$ReceiveTimer.start(0.2)
	
	velocity = dir * SPEED
	if move_and_slide():
		var body := get_last_slide_collision().get_collider()
		if body.is_in_group("lose"):
			print("lose")
		if body.is_in_group("pallete"):
			var body_ball_dir: Vector2 = (body.position + body.bounce_offset).direction_to(position)
			var body_velocty_dir = body.velocity.normalized()
			dir = (body_velocty_dir * 0.3 + body_ball_dir).normalized()
		else:
			dir = dir.bounce(get_last_slide_collision().get_normal())
	
		$BounceSFX.play()


func _on_reset(side):
	position = initial_pos
	dir = Vector2.RIGHT * side
	


func _on_receive_timer_timeout():
	can_receive_ball_pos = true
