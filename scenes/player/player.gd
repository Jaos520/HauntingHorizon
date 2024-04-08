class_name Player
extends CharacterBody3D

#Параметры передвижения
const CAMERA_FOV_DEF = 75.0
const CAMERA_FOV_RUN = 90.0
const WALK_SPEED = 2.0
const RUN_SPEED = 5.0
const JUMP_VELOCITY = 4.5

#Режимы передвижения
const MODE_DRIVE = "drive" #управление машиной
const MODE_LEGS = "legs" #управление персонажем

@export var _bullet_scene: PackedScene

@onready var gun_ray := $Head/Camera3d/RayCast3d as RayCast3D
@onready var cam := $Head/Camera3d as Camera3D
@onready var cam_head := $Head as Node3D
@onready var cam_pos := $playerModel/MainArmature/Skeleton3D/HeadBone/CamPos as Node3D
@onready var anim := $playerModel/AnimationTree as AnimationTree
@onready var model := $playerModel as Node3D
@onready var gui_debug := $GUI/Label as Label

var mouse_sensibility = 200
var mouse_relative_x = 0
var mouse_relative_y = 0
var speed = 0.0
var camera_fov = 75.0
var player_velocity = 0.0
var input_dir: Vector2
var movement_mode: String
var action_car_enter: bool = false
var car: Car = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	#Captures mouse and stops rgun from hitting yourself
	gun_ray.add_exception(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	movement_mode = MODE_LEGS
	anim.active = true

func _process(delta):
	# Camera fix
	cam_head.global_transform.origin = cam_pos.global_transform.origin
	cam.fov = camera_fov
	
	# Контроль анимаций
	animation_control()
	
func _physics_process(delta):
	
	if (action_car_enter):
		
		#self.global_transform.origin = carObj.global_transform.origin
		#self.rotation_degrees = carObj.rotation_degrees
		#self.rotation_degrees.y += 90
		
		action_car_enter = false
		movement_mode = MODE_DRIVE
		car.controlActive = true
			
		return
	elif (car):
		#self.global_transform.origin = carObj.global_transform.origin
		#self.rotation_degrees = carObj.rotation_degrees
		#self.rotation_degrees.y += 90
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
		
		input_dir = Input.get_vector("moveLeft", "moveRight", "moveUp", "moveDown")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			player_velocity = speed
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			player_velocity = lerp(player_velocity, 0.0, 0.1)
			velocity.x = lerp(velocity.x, 0.0, 0.1)
			velocity.z = lerp(velocity.z, 0.0, 0.1)
	
	move_and_slide()
	
	
func _input(event):
	if event is InputEventMouseMotion:
		
		if (car):
			cam.rotation.y -= event.relative.x / mouse_sensibility
			cam.rotation.y = clamp(cam.rotation.y, deg_to_rad(0), deg_to_rad(180) )
		else:
			rotation.y -= event.relative.x / mouse_sensibility
		
		cam.rotation.x -= event.relative.y / mouse_sensibility
		cam.rotation.x = clamp(cam.rotation.x, deg_to_rad(-80), deg_to_rad(90) )
		mouse_relative_x = clamp(event.relative.x, -50, 50)
		mouse_relative_y = clamp(event.relative.y, -50, 10)

func shoot():
	if not gun_ray.is_colliding():
		return
	var bullet_inst = _bullet_scene.instantiate() as Node3D
	bullet_inst.set_as_top_level(true)
	get_parent().add_child(bullet_inst)
	bullet_inst.global_transform.origin = gun_ray.get_collision_point() as Vector3
	bullet_inst.look_at((gun_ray.get_collision_point()+gun_ray.get_collision_normal()),Vector3.BACK)
	print(gun_ray.get_collision_point())
	print(gun_ray.get_collision_point()+gun_ray.get_collision_normal())
	
func animation_control():
	if movement_mode == MODE_LEGS:
		animation_legs()
	elif movement_mode == MODE_DRIVE:
		animation_drive()
	
func animation_legs():
	anim["parameters/StateMachineLegs/Walk/blend_position"].x = move_toward(anim["parameters/StateMachineLegs/Walk/blend_position"].x, input_dir.x, 0.1)
	anim["parameters/StateMachineLegs/Walk/blend_position"].y = move_toward(anim["parameters/StateMachineLegs/Walk/blend_position"].y, input_dir.y, 0.1)
	anim["parameters/StateMachineLegs/Run/blend_position"].x = move_toward(anim["parameters/StateMachineLegs/Run/blend_position"].x, input_dir.x, 0.1)
	anim["parameters/StateMachineLegs/Run/blend_position"].y = move_toward(anim["parameters/StateMachineLegs/Run/blend_position"].y, input_dir.y, 0.1)
	
	if player_velocity <= 0.5:
		anim["parameters/StateMachineLegs/conditions/idle"] = true
		anim["parameters/StateMachineLegs/conditions/walk"] = false
		anim["parameters/StateMachineLegs/conditions/run"] = false
		anim["parameters/TimeScaleLegs/scale"] = 1.0
	elif player_velocity <= WALK_SPEED:
		anim["parameters/StateMachineLegs/conditions/idle"] = false
		anim["parameters/StateMachineLegs/conditions/walk"] = true
		anim["parameters/StateMachineLegs/conditions/run"] = false
		anim["parameters/TimeScaleLegs/scale"] = (player_velocity/WALK_SPEED) * 1.2
	elif player_velocity > WALK_SPEED:
		anim["parameters/StateMachineLegs/conditions/idle"] = false
		anim["parameters/StateMachineLegs/conditions/walk"] = false
		anim["parameters/StateMachineLegs/conditions/run"] = true
		anim["parameters/TimeScaleLegs/scale"] = player_velocity/RUN_SPEED
	
func animation_drive():
	if (car.steering > 0.05):
		anim["parameters/StateMachineDrive/conditions/idle"] = false
		anim["parameters/StateMachineDrive/conditions/left"] = true
		anim["parameters/StateMachineDrive/conditions/right"] = false
	elif (car.steering < -0.05):
		anim["parameters/StateMachineDrive/conditions/idle"] = false
		anim["parameters/StateMachineDrive/conditions/left"] = false
		anim["parameters/StateMachineDrive/conditions/right"] = true
	else:
		anim["parameters/StateMachineDrive/conditions/idle"] = true
		anim["parameters/StateMachineDrive/conditions/left"] = false
		anim["parameters/StateMachineDrive/conditions/right"] = false
	
func set_movement_mode(mode):
	movement_mode = mode
	anim["parameters/Transition/transition_request"] = movement_mode
	
	
func carEnter(node):
	get_node("CollisionShape3d").disabled = true
	action_car_enter = true
	car = node
	
