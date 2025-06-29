extends CharacterBody3D

const SENSITIVITY = 0.003
var SPEED = 15.0
const JUMP_VELOCITY = 6.5
var jumps_left = 3
var hp = 100
# Dash Vars
const MAX_DASHES = 3
var dash_count = MAX_DASHES
var is_dashing = false
var dash_time = 0.3
var dash_timer = 0.0
var dash_speed = 30.0
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
@onready var world = $"../"
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
var direction = null
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
	if hp<=0:
		return
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			shoot()
		
func _process(delta: float) -> void:
	if hp<=0:
		return

	if hp<=0:
		eyeball.get_child(0).play_anim = false	
	if dash_in_cooldown:
		dash_count = int(3-dash_cooldown.time_left)

func _physics_process(delta: float) -> void:
	if hp<=0:
		return
	if shoot_timer>0:
		shoot_timer -= delta
	

	idx+=0.05
	eyeball.position.y -= sin(idx)/2000
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	

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
		if is_slaming:
			velocity.y = JUMP_VELOCITY*2
		else:
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
	if hp<=0:
		return
	dash_count = MAX_DASHES
	dash_in_cooldown = false
	
	dash_cooldown.stop()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if hp<=0:
		return
	if is_slaming:
		
		if body.name == "slam_ground_body":
			body.fall()
		
		camera.shake(1.8)	
		await  get_tree().create_timer(0.3).timeout
		can_slam = false
		is_slaming = false
	

func _on_area_3d_area_entered(area: Area3D) -> void:
	
	if area.is_in_group("slam_area"):
		if is_slaming:
			
			area.get_parent().kill()
			velocity.y = JUMP_VELOCITY
			camera.shake(2)
			is_slaming = false
			

# NEW SHOOTING FUNCTIONS
func shoot():
	# Get crosshair target position
	var target_pos = get_crosshair_target()
	var muzzle_pos = shoot_point.global_position
	
	# Calculate direction from muzzle to target
	var shoot_direction = (target_pos - muzzle_pos).normalized()
	
	# Spawn bullet
	spawn_bullet(muzzle_pos, shoot_direction)
	
func get_crosshair_target() -> Vector3:
	# Get screen center (crosshair position)
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2
	
	# Project ray from camera through crosshair
	var from = camera.project_ray_origin(screen_center)
	var to = from + camera.project_ray_normal(screen_center) * 1000.0
	
	# Raycast to find target point
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]  # Don't hit the player
	var result = space_state.intersect_ray(query)
	
	# Return hit point or max range point
	return result.position if result else to

func spawn_bullet(start_pos: Vector3, shoot_direction: Vector3):
	# Create bullet instance
	var bullet = bullet_scene.instantiate()
	
	# Add bullet to bullets node (or scene if bullets node doesn't exist)
	if bullets:
		bullets.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	
	# Set bullet position and direction
	bullet.global_position = start_pos
	bullet.initialize_bullet(shoot_direction)
