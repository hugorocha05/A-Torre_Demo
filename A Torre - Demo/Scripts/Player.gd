extends CharacterBody2D

# ----------------------------
# Character variables
# ----------------------------
var max_speed := 300.0  # Max speed that the player-character can achieve while running
var acceleration := 10.0  # Acceleration value of the player-character, permits smooth movement
var input_vector := Vector2.ZERO  # The input vector is a Vector2 I'm using to determine the direction of movement with x and y values ranging from -1 to 1. Ex: (-1, 0) means the input vector is "moving left" and (0, 1) means it's "moving down"

var dash_speed := 900.0  # Speed of the player while dashing
var dash_direction := Vector2.RIGHT  # Used to keep track of the last movement direction so the dash can be predictable and consistent
var dash_duration := 0.15
var can_dash := true  # Flag used to apply a dash cooldown
var dash_cooldown_duration := 1.5 

enum MovementState {  # Basic state machine
	NORMAL,
	DASHING
}

var movement_state := MovementState.NORMAL  # Starting state is the normal state

# ---------------------------
# Setup
# ----------------------------

# Accessing child nodes
@onready var dash_timer = $Timers/DashTimer
@onready var dash_cooldown = $Timers/DashCooldown

func _ready():
	# Setting up the timer wait times
	dash_timer.wait_time = dash_duration
	dash_cooldown.wait_time = dash_cooldown_duration
	
	# Adding player to the Player group, this allows easier reference to the player node
	add_to_group("Player")

# ----------------------------
# Movement
# ----------------------------
func get_input() -> void: 
	# Get input actions
	input_vector = Input.get_vector("Move Left", "Move Right", "Move Up", "Move Down")  # get_vector() returns a result input vector from the 4 directional input strengths, the input actions follow this order: negative x, positive x, negative y, positive y. It is essentially the same as creating 4 if statements and manually changing the input vector value depending on the direction. This result vector is already normalized so we don't have to do it manually. We normalize the input vector to prevent uneven movement when going diagonally
	
	if Input.is_action_just_pressed("Dash") and movement_state != MovementState.DASHING and can_dash:  # Checks that the dash button was pressed and then allows the player to dash if they aren't already dashing (so they can't dash twice at the same time) and the can_dash checks if the dash ability isn't in cooldown
		dash()
	
func update_velocity(delta: float) -> void:
	if movement_state == MovementState.NORMAL:
		if input_vector != Vector2.ZERO:  # If there are movement inputs
			dash_direction = input_vector  # Stores the movement direction so the dash corresponds with the player movement
			apply_acceleration(delta)  # Accelerates the player in the direction they are going, allows smooth movement
		else:
			apply_friction(delta)  # Decelarates the player when they aren't moving, allows smooth stopping
		
func apply_acceleration(delta: float) -> void:
	velocity = velocity.lerp(input_vector * max_speed, acceleration * delta)  # lerp gradually brings the velocity from the current value to the player-character's max speed in increments according to the player's acceleration, creating an acceleration effect. We multiply by delta so the movement is frame independent

func apply_friction(delta: float) -> void:
	velocity = velocity.lerp(Vector2.ZERO, Globals.FRICTION * delta)  # lerp gradually brings velocity from the current value to a null vector in increments according to the FRICTION value, creating a deceleration effect. We multiply by delta so the movement is frame independent. Globals is the name of my singleton/autoload script that contains all the global/environmental variables (check Globals.gd)

func dash():
	movement_state = MovementState.DASHING  # Update state
	velocity = dash_speed * dash_direction  # The actual dash logic
	can_dash = false
	
	# Start dash timers
	dash_timer.start()
	dash_cooldown.start()
	
func _on_dash_timer_timeout():
	movement_state = MovementState.NORMAL  # When the dash duration runs out, update the state back to normal mode. That way the velocity update goes back to usual so acceleration/friction can be applied
	
func _on_dash_cooldown_timeout():
	can_dash = true  # Once the cooldown is over, the player gains back the ability to dash
	print("can dash\n")

# ----------------------------
# Processing
# ----------------------------
func _physics_process(delta: float) -> void:
	get_input()
	update_velocity(delta)
	move_and_slide()  # Godot's built-in movement function, moves character based on the 'velocity' attribute
