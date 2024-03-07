extends CharacterBody3D

@onready var gunRay = $Head/Camera3d/RayCast3d as RayCast3D
@onready var Cam = $Head/Camera3d as Camera3D
@onready var CamHead = $Head as Node3D
@onready var CamPos = $playerModel/MainArmature/Skeleton3D/HeadBone/CamPos as Node3D
@onready var Anim = $playerModel/AnimationTree as AnimationTree
@onready var Model = $playerModel as Node3D
@onready var GUI = $GUI/Label as Label
@export var _bullet_scene : PackedScene
var mouseSensibility = 200
var mouse_relative_x = 0
var mouse_relative_y = 0
var speed = 0.0
var camera_fov = 75.0
var playerVelocity = 0.0

var inputDir : Vector2

const CAMERA_FOV_DEF = 75.0
const CAMERA_FOV_RUN = 90.0
const WALK_SPEED = 2.0
const RUN_SPEED = 5.0
const JUMP_VELOCITY = 4.5

var actionCarEnter = false
var carObj = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	#Captures mouse and stops rgun from hitting yourself
	gunRay.add_exception(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	Anim.active = true
	Anim["parameters/Transition/transition_request"] = "legs"

func _process(delta):
	# Camera fix
	CamHead.global_transform.origin = CamPos.global_transform.origin
	Cam.fov = camera_fov
	
	animation_tree(playerVelocity, inputDir)
	
func _physics_process(delta):
	
	if (actionCarEnter):
		
		self.global_transform.origin = carObj.global_transform.origin
		self.rotation_degrees = carObj.rotation_degrees
		self.rotation_degrees.y += 90
		
		if (!Anim["parameters/OneShot/active"]):
			actionCarEnter = false
			Anim["parameters/Transition/transition_request"] = "drive"
			carObj.controlActive = true
		return
	elif (carObj):
		self.global_transform.origin = carObj.global_transform.origin
		self.rotation_degrees = carObj.rotation_degrees
		self.rotation_degrees.y += 90
		animation_tree_drive()
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Handle Shooting
	if Input.is_action_just_pressed("Shoot"):
		shoot()
	# Get the input direction and handle the movement/deceleration.
	if is_on_floor():
		if Input.is_action_pressed("Run"):
			camera_fov = lerp(camera_fov, CAMERA_FOV_RUN, 0.01)
			speed = move_toward(speed, WALK_SPEED + RUN_SPEED, 0.02)
		else:
			camera_fov = lerp(camera_fov, CAMERA_FOV_DEF, 0.01)
			speed = move_toward(speed, WALK_SPEED, 0.04)
		
		inputDir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
		var direction = (transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized()
		if direction:
			playerVelocity = speed
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			playerVelocity = lerp(playerVelocity, 0.0, 0.1)
			velocity.x = lerp(velocity.x, 0.0, 0.1)
			velocity.z = lerp(velocity.z, 0.0, 0.1)
	
	move_and_slide()
	
	
func _input(event):
	if event is InputEventMouseMotion:
		
		if (carObj):
			Cam.rotation.y -= event.relative.x / mouseSensibility
			Cam.rotation.y = clamp(Cam.rotation.y, deg_to_rad(0), deg_to_rad(180) )
		else:
			rotation.y -= event.relative.x / mouseSensibility
		
		Cam.rotation.x -= event.relative.y / mouseSensibility
		Cam.rotation.x = clamp(Cam.rotation.x, deg_to_rad(-80), deg_to_rad(90) )
		mouse_relative_x = clamp(event.relative.x, -50, 50)
		mouse_relative_y = clamp(event.relative.y, -50, 10)

func shoot():
	if not gunRay.is_colliding():
		return
	var bulletInst = _bullet_scene.instantiate() as Node3D
	bulletInst.set_as_top_level(true)
	get_parent().add_child(bulletInst)
	bulletInst.global_transform.origin = gunRay.get_collision_point() as Vector3
	bulletInst.look_at((gunRay.get_collision_point()+gunRay.get_collision_normal()),Vector3.BACK)
	print(gunRay.get_collision_point())
	print(gunRay.get_collision_point()+gunRay.get_collision_normal())
	
func animation_tree(speed : float, direction : Vector2):
	Anim["parameters/StateMachineLegs/Walk/blend_position"].x = move_toward(Anim["parameters/StateMachineLegs/Walk/blend_position"].x, direction.x, 0.1)
	Anim["parameters/StateMachineLegs/Walk/blend_position"].y = move_toward(Anim["parameters/StateMachineLegs/Walk/blend_position"].y, direction.y, 0.1)
	Anim["parameters/StateMachineLegs/Run/blend_position"].x = move_toward(Anim["parameters/StateMachineLegs/Run/blend_position"].x, direction.x, 0.1)
	Anim["parameters/StateMachineLegs/Run/blend_position"].y = move_toward(Anim["parameters/StateMachineLegs/Run/blend_position"].y, direction.y, 0.1)
	
	
	if speed <= 0.5:
		Anim["parameters/StateMachineLegs/conditions/idle"] = true
		Anim["parameters/StateMachineLegs/conditions/walk"] = false
		Anim["parameters/StateMachineLegs/conditions/run"] = false
		Anim["parameters/TimeScaleLegs/scale"] = 1.0
	elif speed <= WALK_SPEED:
		Anim["parameters/StateMachineLegs/conditions/idle"] = false
		Anim["parameters/StateMachineLegs/conditions/walk"] = true
		Anim["parameters/StateMachineLegs/conditions/run"] = false
		Anim["parameters/TimeScaleLegs/scale"] = (speed/WALK_SPEED) * 1.2
	elif speed > WALK_SPEED:
		Anim["parameters/StateMachineLegs/conditions/idle"] = false
		Anim["parameters/StateMachineLegs/conditions/walk"] = false
		Anim["parameters/StateMachineLegs/conditions/run"] = true
		Anim["parameters/TimeScaleLegs/scale"] = speed/RUN_SPEED
	
func animation_tree_drive():
	if (carObj.steering > 0.05):
		Anim["parameters/StateMachineDrive/conditions/idle"] = false
		Anim["parameters/StateMachineDrive/conditions/left"] = true
		Anim["parameters/StateMachineDrive/conditions/right"] = false
	elif (carObj.steering < -0.05):
		Anim["parameters/StateMachineDrive/conditions/idle"] = false
		Anim["parameters/StateMachineDrive/conditions/left"] = false
		Anim["parameters/StateMachineDrive/conditions/right"] = true
	else:
		Anim["parameters/StateMachineDrive/conditions/idle"] = true
		Anim["parameters/StateMachineDrive/conditions/left"] = false
		Anim["parameters/StateMachineDrive/conditions/right"] = false
	
func carEnter(car):
	get_node("CollisionShape3d").disabled = true
	Anim["parameters/OneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	car.Anim["parameters/OneShot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	actionCarEnter = true
	carObj = car
	
