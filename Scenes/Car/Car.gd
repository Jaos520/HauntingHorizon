extends VehicleBody3D

@onready var driverPosition = $driverPosition as Node3D
@onready var Anim = $AnimationPlayer as AnimationPlayer
var body = null
var controlActive


# Called when the node enters the scene tree for the first time.
func _ready():
	controlActive = false
	pass # Replace with function body.
	
func _physics_process(delta):
	if (controlActive):
		steering = Input.get_axis("moveRight","moveLeft") * 0.3
		engine_force = Input.get_axis("moveDown","moveUp") * 25
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_left_door_interacted(body):
	body.carEnter(self)
	Anim.current_animation = "SedanA_DoorLAction"
	pass # Replace with function body.


func _on_right_door_interacted(body):
	body.carEnter(self)
	pass # Replace with function body.
