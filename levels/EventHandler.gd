extends Node3D

@onready var player = get_node("/root/World/Player")

var events = {}
var action

# Called when the node enters the scene tree for the first time.
func _ready():
	events["player_enter_car"] = InputEventAction.new()
	events["player_enter_car"].action = "player_enter_car"
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	Input.parse_input_event(events["player_enter_car"])
	player.GUI.text = str(events["player_enter_car"].pressed)
	pass
