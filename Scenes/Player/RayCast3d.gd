extends RayCast3D

#@onready var player = get_node("/root/World/Player")
@onready var InteractLabel = get_node("/root/World/Player/GUI/InteractLabel")
var obj
var distance

# Called when the node enters the scene tree for the first time.
func _ready():
	add_exception(owner)
	
func _physics_process(delta):
	InteractLabel.text = ""
	if is_colliding():
		obj = get_collider()
		distance = global_transform.origin.distance_to(get_collision_point())
		if distance < 1:
			if obj is Interactable:
				InteractLabel.text = obj.get_prompt()
			
				if Input.is_action_just_pressed(obj.prompt_action):
					obj.interact(owner)
