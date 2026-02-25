extends CharacterBody2D

# ----------------------------
# Variables
# ----------------------------

# Variables used to define the stats at runtime
var max_speed := 300.0  # Max speed that the player-character can achieve while running
var acceleration := 10.0  # Acceleration value of the player-character, permits smooth movement
var input_vector := Vector2.ZERO  # The input vector is a Vector2 I'm using to determine the direction of movement with x and y values ranging from -1 to 1. Ex: (-1, 0) means the input vector is "moving left" and (0, 1) means it's "moving down"

var dash_speed := 900.0  # Speed of the player while dashing
var dash_direction := Vector2.RIGHT  # Used to keep track of the last movement direction so the dash can be predictable and consistent
var dash_duration := 0.15
var can_dash := true  # Flag used to apply a dash cooldown
var dash_cooldown_duration := 1.5

var health := 3  # How many hits the player can take before dying
var hits_taken := 0  # How many hits the player has currently taken
var bleed_resistance := 5  # How many seconds it takes to die while bleeding

var speed_debuff := 0.10
var acceleration_debuff := 0.05
var dash_speed_debuff := 0.20

enum MovementState {  # Basic state machine
	NORMAL,
	DASHING,
	DEAD
}

var movement_state := MovementState.NORMAL  # Starting state is the normal state

# ---------------------------
# Setup
# ----------------------------
var defaults := {}  # Dictionary used to store the default values of variables

# Accessing child nodes
@onready var dash_timer = $Timers/DashTimer
@onready var dash_cooldown = $Timers/DashCooldown
@onready var hit_flash_timer = $Timers/HitFlashTimer
@onready var bleed_timer = $Timers/BleedTimer
@onready var sprite = $Sprite2D

func _ready():
	# Setting up the timer wait times
	dash_timer.wait_time = dash_duration
	dash_cooldown.wait_time = dash_cooldown_duration
	bleed_timer.wait_time = bleed_resistance
	
	# Taking a snapshot of the default values before running
	defaults = {
		# Movement core
		"max_speed": max_speed,
		"acceleration": acceleration,

		# Dash system
		"dash_speed": dash_speed,
		"dash_direction": dash_direction,
		"dash_duration": dash_duration,
		"can_dash": can_dash,
		"dash_cooldown_duration": dash_cooldown_duration,

		# Health / damage
		"health": health,
		"hits_taken": hits_taken,
		"bleed_resistance": bleed_resistance,

		# Debuffs
		"speed_debuff": speed_debuff,
		"acceleration_debuff": acceleration_debuff,
		"dash_speed_debuff": dash_speed_debuff
	}
	
	# Adding player to the Player group, this allows easier reference to the player node
	add_to_group("Player")

# ----------------------------
# Input
# ----------------------------
func get_input() -> void: 
	# Get input actions
	input_vector = Input.get_vector("Move Left", "Move Right", "Move Up", "Move Down")  # get_vector() returns a result input vector from the 4 directional input strengths, the input actions follow this order: negative x, positive x, negative y, positive y. It is essentially the same as creating 4 if statements and manually changing the input vector value depending on the direction. This result vector is already normalized so we don't have to do it manually. We normalize the input vector to prevent uneven movement when going diagonally
	
	if Input.is_action_just_pressed("Dash") and movement_state == MovementState.NORMAL and can_dash:  # Checks that the dash button was pressed and then allows the player to dash if they aren't already dashing (so they can't dash twice at the same time) and the can_dash checks if the dash ability isn't in cooldown
		dash()
		
	if Input.is_action_just_pressed("Take Hit (Testing)") and movement_state != MovementState.DEAD:  # TESTING PURPOSES ONLY
		take_hit(1)
		
# ----------------------------
# Movement
# ----------------------------
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

# ----------------------------
# Dash
# ----------------------------
func dash() -> void:
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
# Health/Damage
# ----------------------------
func take_hit(hit_value: int) -> void:
	print("hit\n")
	
	hits_taken += hit_value
	sprite.modulate = Color.CRIMSON  # Flash when hit
	hit_flash_timer.start()
	
	update_movement_stats()
	update_hurt_state()
	
func update_movement_stats() -> void:
	# The calculations below consider the following logic: if I want to reduce a variable by 10%, that's the same as making that variable be worth 90% of it's original value (since 100% - 10% = 90%). In code this would be variable = 0.90 * variable (remember that percentages multiply the original value) or you could also write it as variable = (1 - 0.10) * variable. Finally, I want the reduction to be proportional to the amount of hits taken, therefore me multiply the original reduction by the hits so if the player is hit once we reduce speed by 10% (10 * 1) but if he's hit twice we reduce the speed by 20% (10 * 2). So in the end we have 1 - (10% * hits taken) as the number we should multiply the original value by to get the new one.
	max_speed = (1 - (speed_debuff * hits_taken)) * defaults["max_speed"]
	acceleration = (1 - (acceleration_debuff * hits_taken)) * defaults["acceleration"]
	dash_speed = (1 - (dash_speed_debuff * hits_taken)) * defaults["dash_speed"]
	
	max_speed = clamp(max_speed, 0.0, defaults["max_speed"])
	acceleration = clamp(acceleration, 0.0, defaults["acceleration"])
	dash_speed = clamp(dash_speed, 0.0, defaults["dash_speed"])
	
	print("Hits Taken: ", hits_taken)
	print("Speed: ", max_speed)
	print("Acceleration: ", acceleration)
	print("Dash Speed: ", dash_speed)
	print("\n")
	
func update_hurt_state() -> void:
	if hits_taken >= health:
		die()
		
	if health - hits_taken == 1:
		bleed()
	
func die() -> void:
	stop_timers()
	movement_state = MovementState.DEAD
	sprite.modulate = Color.DIM_GRAY  # Simple color change  to visualize death
	
	print("DEAD\n")
	
func bleed() -> void:
	if bleed_timer.is_stopped():
		print("Bleeding (", bleed_resistance, " seconds til death)")
		bleed_timer.start()

func _on_bleed_timer_timeout():
	die()

func _on_hit_flash_timer_timeout():
	sprite.modulate = Color.WHITE
	
# ----------------------------
# Processing
# ----------------------------
func stop_timers() -> void:
	# Stop all timers
	dash_timer.stop()
	dash_cooldown.stop()
	hit_flash_timer.stop()
	bleed_timer.stop()

func reset() -> void:
	for key in defaults:
		set(key, defaults[key])

	# Reinitialize dynamic state
	movement_state = MovementState.NORMAL
	input_vector = Vector2.ZERO
	velocity = Vector2.ZERO

	stop_timers()

	# Reapply timer configs
	dash_timer.wait_time = dash_duration
	dash_cooldown.wait_time = dash_cooldown_duration
	bleed_timer.wait_time = bleed_resistance

	sprite.modulate = Color.WHITE
	
func _physics_process(delta: float) -> void:
	if movement_state != MovementState.DEAD:
		get_input()
		update_velocity(delta)
		move_and_slide()  # Godot's built-in movement function, moves character based on the 'velocity' attribute
