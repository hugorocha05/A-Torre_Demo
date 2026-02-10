extends CharacterBody2D

var player_max_speed := 300.0  # Speed of the player-character, can be changed
var player_acceleration := 15.0

func update_velocity(delta):  # Basic player-character movement 
	
	var input_vector := Vector2.ZERO  # Resets input_vector
	
	# Get input actions
	input_vector.x = Input.get_axis("Move Left", "Move Right")
	input_vector.y = Input.get_axis("Move Up", "Move Down")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()  # We normalize the input vector to prevent uneven movement when going diagonally
		apply_acceleration(input_vector, delta)
	else:
		apply_friction(delta)
		
func apply_friction(delta):
	velocity = velocity.lerp(Vector2.ZERO, Globals.FRICTION * delta)  # lerp gradually brings velocity from the current value to a null vector in increments according to the FRICTION value, creating a deceleration effect. We multiply by delta so the movement is frame independent

func apply_acceleration(input_vector: Vector2, delta):
	velocity = velocity.lerp(input_vector * player_max_speed, player_acceleration * delta)  # lerp gradually brings the velocity from the current value to the player-character's max speed in increments according to the player's acceleration, creating an acceleration effect. We multiply by delta so the movement is frame independent

func _physics_process(delta):
	update_velocity(delta)  # 8-Directional Movement
	
	print(velocity)

	move_and_slide()  # Godot's built-in movement function, moves character based on the 'velocity' attribute
