extends Node2D

@onready var player = get_tree().get_first_node_in_group("Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("Reset") and player.movement_state == player.MovementState.DEAD:
		reset()

func reset() -> void:
	player.reset()
	player.global_position = Vector2(640, 320)
