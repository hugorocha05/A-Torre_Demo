extends CharacterBody2D

# ----------------------------
# Character variables
# ----------------------------
var max_speed := 150.0  # Max speed that the enemy can achieve while running
var acceleration := 6.0  # Acceleration value of the enemy, permits smooth movement
var movement_direction := Vector2.ZERO  # The direction that the enemy should walk in, starts as a null vector to be changed later
var chase_buffer := 160  # The distance the enemy keeps from the player while chasing, that way the enemy shouldn't overlap with the player
var friction := 5  # friction value that permits more subtle deceleration

enum MovementState {  # Basic state machine
	CHASING,
	STOPPED
}

var movement_state := MovementState.CHASING  # Starting state is to chase the player

# ---------------------------
# Setup
# ----------------------------

# Accessing the player scene/node
@onready var player := get_tree().get_first_node_in_group("Player")  # Reference to the player node, even if the path or name is changed. This works because in the player script we add the player node to the Player group (check Player.gd)

# ----------------------------
# Movement
# ----------------------------
func get_movement_direction() -> void:
	if global_position.distance_to(player.global_position) <= chase_buffer:  # if the enemy is "too close" to the player, change its movement state so it stops chasing
		movement_state = MovementState.STOPPED
		movement_direction = Vector2.ZERO  # Resets the movement direction to avoid to avoid sliding/jittering
	else:
		movement_state = MovementState.CHASING
		movement_direction = (player.global_position - global_position).normalized()  # The direction the player should move in is the position it's currently at minus the position of the player, all that normalized. That way we get a direction vector that points from the enemy to the player
	
func update_velocity(delta: float) -> void:
	if movement_state == MovementState.CHASING:  # If the enemy is in chasing mode
		apply_acceleration(delta)  # Accelerates the enemy in the direction they are going, allows smooth movement
	else:
		apply_friction(delta)  # Decelarates the enemy when they aren't chasing, allows smooth stopping
		
func apply_acceleration(delta: float) -> void:
	velocity = velocity.lerp(movement_direction * max_speed, acceleration * delta)  # lerp gradually brings the velocity from the current value to the player-character's max speed in increments according to the player's acceleration, creating an acceleration effect. We multiply by delta so the movement is frame independent

func apply_friction(delta: float) -> void:
	velocity = velocity.lerp(Vector2.ZERO, friction * delta)  # lerp gradually brings velocity from the current value to a null vector in increments according to the FRICTION value, creating a deceleration effect. We multiply by delta so the movement is frame independent. Globals is the name of my singleton/autoload script that contains all the global/environmental variables (check Globals.gd)

# ----------------------------
# Processing
# ----------------------------
func _physics_process(delta: float) -> void:
	if player:
		get_movement_direction()
		update_velocity(delta)
		move_and_slide()  # Godot's built-in movement function, moves character based on the 'velocity' attribute

	
