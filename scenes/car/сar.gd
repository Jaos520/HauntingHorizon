class_name Car
extends VehicleBody3D

@onready var body = $SedanA_Body as Node3D
@onready var Anim = $AnimationTree as AnimationTree
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

func animation_tree():
	if (steering > 0.05):
		Anim["parameters/StateMachine/conditions/idle"] = false
		Anim["parameters/StateMachine/conditions/left"] = true
		Anim["parameters/StateMachine/conditions/right"] = false
	elif (steering < -0.05):
		Anim["parameters/StateMachine/conditions/idle"] = false
		Anim["parameters/StateMachine/conditions/left"] = false
		Anim["parameters/StateMachine/conditions/right"] = true
	else:
		Anim["parameters/StateMachine/conditions/idle"] = true
		Anim["parameters/StateMachine/conditions/left"] = false
		Anim["parameters/StateMachine/conditions/right"] = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_left_door_interacted(body):
	body.carEnter(self)
	pass # Replace with function body.
