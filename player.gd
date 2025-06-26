extends CharacterBody3D

const SENSITIVITY = 0.003
var SPEED = 15.0
const JUMP_VELOCITY = 6.5
var jumps_left = 3

# Dash Vars
const MAX_DASHES = 3
var dash_count = MAX_DASHES
var is_dashing = false
var dash_time = 0.3
var dash_timer = 0.0
var dash_speed = 40.0
var dash_direction = Vector3.ZERO
var is_sliding = false
var is_slaming = false 
var can_slam = false
var slide_timer = 0.0
var sliding_time = 0.4
var init_x = null
var idx=0
var original_collision_height = 0 
var slide_collision_height = 0
var dash_in_cooldown = false
var head_z_init = 0
@onready var head = $head
@onready var camera = $head/Camera3D 
@onready var dash_cooldown = $DashCountdown
@onready var hand = $head/Camera3D/hand
@onready var sinn = 1
@onready var shoot_point = $head/Camera3D/hand/Marker3D
@onready var bullets = $"../bullets"
@onready var eyeball_hand = $head/Camera3D/eye_ball_hand
@onready var eyeball = $head/Camera3D/eye_ball2
@onready var collision_shape = $CollisionShape3D

var is_shooting = false
var shoot_time = 0.3
var shoot_timer = 0.0
var normal_fov := 75.0
var dash_fov := 70.0
var fov_lerp_speed := 6.0
var bullet_scene = preload("res://bullet.tscn")
var init_hand_z = 0
var init_eyeballhand_z = 0
var init_head_y = 0
func _ready() -> void:
	init_head_y = head.position.y
	init_hand_z = hand.position.z
	init_eyeballhand_z = eyeball_hand.position.z
	head_z_init = head.rotation.z
	var init_x =  head.position.x
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		original_collision_height = capsule.height
		slide_collision_height = original_collision_height * 0.6

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_shooting = true

func _process(delta: float) -> void:
	if dash_in_cooldown:
		dash_count = int(3-dash_cooldown.time_left)

func _physics_process(delta: float) -> void:
	if shoot_timer>0:
		shoot_timer -= delta
	

	idx+=0.05
	eyeball.position.y -= sin(idx)/2000
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	

	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		if is_sliding:
			var capsule = collision_shape.shape
			capsule.height = original_collision_height
			collision_shape.position.y = 0
			is_sliding = false

		can_slam = true
		head.position.y = init_head_y
	else:

		jumps_left = 3
		
	# Jump
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	if Input.is_action_just_pressed("slam"):
		if not is_on_floor() and can_slam:
			velocity.y = -JUMP_VELOCITY*6
			is_slaming = true
		else:
			if direction:
				is_sliding = true
				slide_timer = sliding_time
				camera.fov = dash_fov - 2
				head.position.y -=1
	
	if Input.is_action_just_released("slam") and is_sliding:
		var capsule = collision_shape.shape
		capsule.height = original_collision_height
		collision_shape.position.y = 0

		camera.fov = lerp(camera.fov, dash_fov, fov_lerp_speed * delta)
		head.position.y = init_head_y
		velocity.y = JUMP_VELOCITY
		is_sliding = false

	# Dash


	if Input.is_action_just_pressed("dash") and dash_count > 0 and not is_dashing and direction != Vector3.ZERO:
		is_dashing = true
		dash_timer = dash_time
		dash_direction = direction
		dash_count -= 1
		camera.fov = dash_fov - 2
		
		if dash_count <= 0:
			dash_in_cooldown = true
			dash_cooldown.start()
		camera.shake(1.3)		

	# Dashing Movement
	if is_dashing:
		velocity = dash_direction * dash_speed
		dash_timer -= delta
		
		camera.fov = lerp(camera.fov, dash_fov, fov_lerp_speed * delta)
		
		if dash_timer <= 0.0:
			is_dashing = false
	if is_sliding:
		if not direction.x:
			var capsule = collision_shape.shape
			capsule.height = original_collision_height
			collision_shape.position.y = 0
		
			camera.fov = lerp(camera.fov, dash_fov, fov_lerp_speed * delta)
			head.position.y = init_head_y
			is_sliding = false
			return
		


		velocity = direction * (dash_speed  / 1.5)
		slide_timer -= delta
		camera.fov = dash_fov

		
		var capsule = collision_shape.shape

		capsule.height = slide_collision_height
		collision_shape.position.y = -(original_collision_height - slide_collision_height) / 2
		
		camera.shake(0.5)

	else:
		camera.fov = lerp(camera.fov, normal_fov, fov_lerp_speed * delta)
		head.rotation.z = head_z_init
		# Normal Movement
		if direction:
			init_hand_z = hand.position.z
			init_eyeballhand_z = eyeball_hand.position.z
			var target_velocity = direction * SPEED
			velocity.x = lerp(velocity.x, target_velocity.x, 8 * delta)
			velocity.z = lerp(velocity.z, target_velocity.z, 8 * delta)
			camera.fov = dash_fov+3
			sinn+=0.1
			if is_on_floor():
				camera.rotation.x += sin(sinn)/800
				camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))
				hand.rotation.y += sin(sinn)/200
				hand.rotation.y = clamp(hand.rotation.y, deg_to_rad(-60), deg_to_rad(60))	
				eyeball_hand.position.y -= sin(sinn)/1500
				hand.position.y -= sin(sinn)/1500
				
			
		else:
			velocity.x = lerp(velocity.x, 0.0, 10 * delta)
			velocity.z = lerp(velocity.z, 0.0, 10 * delta)

	move_and_slide()

func _on_dash_countdown_timeout() -> void:
	dash_count = MAX_DASHES
	dash_in_cooldown = false
	
	dash_cooldown.stop()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if is_slaming:
		if body.name == "slam_ground_body":
			body.fall()
		
		camera.shake(1.8)	
		can_slam = false
		is_slaming = false
	
