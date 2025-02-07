extends CharacterBody3D

# Movement
@export var MAX_VELOCITY_AIR = 0.6 # Air control
@export var MAX_VELOCITY_GROUND = 6.0
var MAX_ACCELERATION = 10 * MAX_VELOCITY_GROUND
@export var GRAVITY = 22.0 #15.34
@export var STOP_SPEED = 1.5 #1.5
var JUMP_IMPULSE = sqrt(2 * GRAVITY * 1.5) #sqrt(2 * GRAVITY * 0.85)
@export var PLAYER_WALKING_MULTIPLIER = 0.666
@export var MOUSE_SENSITIVITY : float = 0.025

var direction = Vector3()
var friction = 6 #4 6
var wish_jump
var walking = false

var stored_velocity = Vector3.ZERO


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	
	if event.is_action_pressed("exit"):
		get_tree().quit()
	
	# Mouse lock
	#if Input.is_action_pressed("ui_cancel"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#elif Input.is_action_pressed("mouse_left"):
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Camera rotation
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_handle_camera_rotation(event)
	
func _handle_camera_rotation(event: InputEvent):
	# Rotate the camera based on the mouse movement
	rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
	$Head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
	
	
	# Stop the head from rotating to far up or down + soft clamp
	var head_rot_x = $Head.rotation.x
	var new_head_rot_x = clamp(head_rot_x, deg_to_rad(-90) - (head_rot_x - deg_to_rad(60)) * 0.1, deg_to_rad(60) + (head_rot_x - deg_to_rad(-80)) * 0.1)
	$Head.rotation.x = lerp($Head.rotation.x, new_head_rot_x, 0.35)
	
func _physics_process(delta):
	process_input()
	process_movement(delta)


	GlobalScript.debug.add_property("FPS",GlobalScript.debug.frames_per_second, 1)
	GlobalScript.debug.add_property("Speed",str(velocity.length()).pad_decimals(3), 2)
	GlobalScript.debug.add_property("X rotation", str(rad_to_deg($Head.rotation.x)).pad_decimals(3), 3)

	
func process_input():
	direction = Vector3()
	
	# Movement directions
	if is_on_floor():
		if Input.is_action_pressed("forward"):
			direction -= transform.basis.z
		elif Input.is_action_pressed("backward"):
			direction += transform.basis.z
		if Input.is_action_pressed("left"):
			direction -= transform.basis.x
		elif Input.is_action_pressed("right"):
			direction += transform.basis.x
	
	# Jumping
	wish_jump = Input.is_action_just_pressed("jump")
	
	# Walking
	# walking = Input.is_action_pressed("walk")
	
func process_movement(delta):
	# Get the normalized input direction so that we don't move faster on diagonals
	var wish_dir = direction.normalized()

	if is_on_floor():
		# If wish_jump is true then we won't apply any friction and allow the 
		# player to jump instantly, this gives us a single frame where we can 
		# perfectly bunny hop
		if wish_jump:
			velocity.y = JUMP_IMPULSE
			# Update velocity as if we are in the air
			velocity = update_velocity_air(wish_dir, delta)
			wish_jump = false
		else:
			velocity = update_velocity_ground(wish_dir, delta)
	else:
		# Only apply gravity while in the air
		velocity.y -= GRAVITY * delta
		velocity = update_velocity_air(wish_dir, delta)
	
	# add_debug_property("Current speed", velocity.length())

	# Move the player once velocity has been calculated
	move_and_slide()
	
func accelerate(wish_dir: Vector3, max_velocity: float, delta):
	# Get our current speed as a projection of velocity onto the wish_dir
	var current_speed = velocity.normalized().dot(wish_dir)
	# How much we accelerate is the difference between the max speed and the current speed
	# clamped to be between 0 and MAX_ACCELERATION which is intended to stop you from going too fast
	var add_speed = clamp(max_velocity - current_speed, 0, MAX_ACCELERATION * delta)
	
	return velocity + add_speed * wish_dir
	
func update_velocity_ground(wish_dir: Vector3, delta):
	# Apply friction when on the ground and then accelerate
	var speed = velocity.length()
	
	if speed != 0:
		var control = max(STOP_SPEED, speed)
		var drop = control * friction * delta
		
		# Scale the velocity based on friction
		velocity *= max(speed - drop, 0) / speed
	
	return accelerate(wish_dir, MAX_VELOCITY_GROUND, delta)
	
func update_velocity_air(wish_dir: Vector3, delta):
	# Do not apply any friction
	return accelerate(wish_dir, MAX_VELOCITY_AIR, delta)
