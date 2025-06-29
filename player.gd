extends CharacterBody3D

# === CONSTANTS ===
const SENSITIVITY = 0.003
const JUMP_VELOCITY = 6.5
const MAX_DASHES = 3

# === PLAYER STATS ===
var SPEED = 15.0
var hp = 100
var jumps_left = 3

# === MOVEMENT VARIABLES ===
var dash_count = MAX_DASHES
var is_dashing = false
var is_sliding = false
var is_slaming = false
var can_slam = false
var dash_in_cooldown = false
var is_walking = false
var is_in_air = false

# === TIMERS ===
var dash_time = 0.3
var dash_timer = 0.0
var slide_timer = 0.0
var sliding_time = 0.4
var shoot_timer = 0.0
var shoot_time = 0.3

# === SPEEDS ===
var dash_speed = 30.0

# === COLLISION ===
var original_collision_height = 0
var slide_collision_height = 0

# === CAMERA & FOV SYSTEM ===
var base_fov := 75.0
var walking_fov := 74.0
var running_fov := 73.0
var jump_fov := 70.0
var dash_fov := 68.0
var slide_fov := 67.0
var slam_fov := 70.0

var current_fov := 75.0
var target_fov := 75.0
var fov_transition_speed := 8.0

# === GUN RECOIL SYSTEM ===
var recoil_strength := 0.1
var recoil_recovery_speed := 8.0
var recoil_randomness := 0.1
var current_recoil := Vector3.ZERO
var target_recoil := Vector3.ZERO

# Hand recoil
var hand_recoil_strength := 0.07
var hand_recoil_recovery := 10.0
var hand_current_recoil := Vector3.ZERO
var hand_base_position := Vector3.ZERO
var hand_base_rotation := Vector3.ZERO

# === ANIMATION & EFFECTS ===
var idx = 0
var sinn = 1
var head_z_init = 0
var init_hand_z = 0
var init_eyeballhand_z = 0
var init_head_y = 0

# === MOVEMENT DIRECTION ===
var direction = null
var dash_direction = Vector3.ZERO

# === NODE REFERENCES ===
@onready var head = $head
@onready var camera = $head/Camera3D
@onready var hand = $head/Camera3D/hand
@onready var eyeball_hand = $head/Camera3D/eye_ball_hand
@onready var eyeball = $head/Camera3D/eye_ball2
@onready var shoot_point = $head/Camera3D/hand/Marker3D
@onready var collision_shape = $CollisionShape3D
@onready var dash_cooldown = $DashCountdown
@onready var bullets = $"../bullets"
@onready var world = $"../"

# === RESOURCES ===
var bullet_scene = preload("res://bullet.tscn")

func _ready() -> void:
	_initialize_positions()
	_setup_collision()
	_initialize_camera_system()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _initialize_positions() -> void:
	init_head_y = head.position.y
	init_hand_z = hand.position.z
	init_eyeballhand_z = eyeball_hand.position.z
	head_z_init = head.rotation.z
	
	# Store original hand transform for recoil
	hand_base_position = hand.position
	hand_base_rotation = hand.rotation

func _setup_collision() -> void:
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		original_collision_height = capsule.height
		slide_collision_height = original_collision_height * 0.6

func _initialize_camera_system() -> void:
	current_fov = base_fov
	target_fov = base_fov
	camera.fov = base_fov

func _unhandled_input(event: InputEvent) -> void:
	if hp <= 0:
		return
		
	_handle_mouse_input(event)
	_handle_shooting_input(event)

func _handle_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Apply recoil to mouse sensitivity
		var adjusted_sensitivity = SENSITIVITY * (1.0 + current_recoil.length() * 0.5)
		
		head.rotate_y(-event.relative.x * adjusted_sensitivity)
		camera.rotate_x(-event.relative.y * adjusted_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _handle_shooting_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			shoot()

func _process(delta: float) -> void:
	if hp <= 0:
		_handle_death()
		return
	
	_update_dash_ui()
	_update_eyeball_animation()
	_update_camera_system(delta)
	_update_recoil_system(delta)

func _handle_death() -> void:
	if eyeball.get_child(0).has_method("play_anim"):
		eyeball.get_child(0).play_anim = false

func _update_dash_ui() -> void:
	if dash_in_cooldown:
		dash_count = int(3 - dash_cooldown.time_left)

func _update_eyeball_animation() -> void:
	idx += 0.05
	eyeball.position.y -= sin(idx) / 2000

# === ENHANCED CAMERA SYSTEM ===
func _update_camera_system(delta: float) -> void:
	_determine_target_fov()
	_smooth_fov_transition(delta)

func _determine_target_fov() -> void:
	if is_slaming:
		target_fov = slam_fov
	elif is_dashing:
		target_fov = dash_fov
	elif is_sliding:
		target_fov = slide_fov
	elif is_in_air:
		target_fov = jump_fov
	elif is_walking:
		var speed_factor = velocity.length() / SPEED
		target_fov = lerp(base_fov, running_fov, speed_factor)
	else:
		target_fov = base_fov

func _smooth_fov_transition(delta: float) -> void:
	# Use different transition speeds for different states
	var transition_speed = fov_transition_speed
	
	if is_dashing or is_slaming:
		transition_speed = 15.0  # Faster for dramatic effects
	elif is_sliding:
		transition_speed = 12.0
	elif is_in_air:
		transition_speed = 6.0
	
	current_fov = lerp(current_fov, target_fov, transition_speed * delta)
	camera.fov = current_fov

# === ENHANCED RECOIL SYSTEM ===
func _update_recoil_system(delta: float) -> void:
	# Camera recoil recovery
	current_recoil = current_recoil.lerp(Vector3.ZERO, recoil_recovery_speed * delta)
	
	# Apply recoil to camera
	var recoil_offset = current_recoil
	# You can apply this to camera rotation if needed
	
	# Hand recoil recovery
	hand_current_recoil = hand_current_recoil.lerp(Vector3.ZERO, hand_recoil_recovery * delta)
	
	# Apply hand recoil
	hand.position = hand_base_position - hand_current_recoil
	hand.rotation = hand_base_rotation - hand_current_recoil * 0.2

func _apply_gun_recoil() -> void:
	# Generate random recoil pattern
	var recoil_x = randf_range(-recoil_randomness, recoil_randomness)
	var recoil_y = -recoil_strength + randf_range(-recoil_randomness * 0.5, recoil_randomness * 0.5)
	var recoil_z = randf_range(-recoil_randomness * 0.3, recoil_randomness * 0.3)
	
	# Apply camera recoil
	current_recoil += Vector3(recoil_x, recoil_y, recoil_z)
	target_recoil = current_recoil
	
	# Apply hand recoil (more dramatic)
	var hand_recoil_x = randf_range(-0.1, 0.1)
	var hand_recoil_y = randf_range(-0.05, 0.05)
	var hand_recoil_z = -hand_recoil_strength + randf_range(-0.1, 0.1)
	
	hand_current_recoil += Vector3(hand_recoil_x, hand_recoil_y, hand_recoil_z)
	
	# Add rotation recoil to hand
	var rotation_recoil = Vector3(
		randf_range(-0.2, 0.2),
		randf_range(-0.1, 0.1),
		randf_range(-0.15, 0.15)
	)
	hand_current_recoil += rotation_recoil
	
	# Camera shake for impact
	if camera.has_method("shake"):
		camera.shake(0.8)

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	
	_update_movement_states()
	_update_timers(delta)
	_handle_input_direction()
	_handle_gravity(delta)
	_handle_jumping()
	_handle_slam()
	_handle_dash()
	_handle_sliding(delta)
	_handle_normal_movement(delta)
	
	move_and_slide()

func _update_movement_states() -> void:
	is_walking = direction != Vector3.ZERO and is_on_floor() and not is_dashing and not is_sliding
	is_in_air = not is_on_floor()

func _update_timers(delta: float) -> void:
	if shoot_timer > 0:
		shoot_timer -= delta

func _handle_input_direction() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		_exit_slide_if_airborne()
		can_slam = true
		head.position.y = init_head_y
	else:
		jumps_left = 3

func _exit_slide_if_airborne() -> void:
	if is_sliding:
		var capsule = collision_shape.shape
		capsule.height = original_collision_height
		collision_shape.position.y = 0
		is_sliding = false

func _handle_jumping() -> void:
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY * (2 if is_slaming else 1)
		jumps_left -= 1
		
		# Jump FOV effect
		if camera.has_method("shake"):
			camera.shake(0.3)

func _camera_rotation():
	if Input.is_action_just_pressed("move_left"):
		for i in camera.get_children():
			i.rotation.z += 1

func _handle_slam() -> void:
	if Input.is_action_just_pressed("slam"):
		if not is_on_floor() and can_slam:
			_start_slam()
		elif direction:
			_start_slide()
	
	if Input.is_action_just_released("slam") and is_sliding:
		_end_slide()

func _start_slam() -> void:
	velocity.y = - JUMP_VELOCITY * 6
	is_slaming = true
	
	# Slam camera effect
	if camera.has_method("shake"):
		camera.shake(1.0)

func _start_slide() -> void:
	is_sliding = true
	slide_timer = sliding_time
	head.position.y -= 1
	
	# Slide camera effect
	if camera.has_method("shake"):
		camera.shake(0.5)

func _end_slide() -> void:
	var capsule = collision_shape.shape
	capsule.height = original_collision_height
	collision_shape.position.y = 0
	head.position.y = init_head_y
	velocity.y = JUMP_VELOCITY
	is_sliding = false

func _handle_dash() -> void:
	if Input.is_action_just_pressed("dash") and _can_dash():
		_start_dash()
	
	if is_dashing:
		_update_dash(get_physics_process_delta_time())

func _can_dash() -> bool:
	return dash_count > 0 and not is_dashing and direction != Vector3.ZERO

func _start_dash() -> void:
	is_dashing = true
	dash_timer = dash_time
	dash_direction = direction
	dash_count -= 1
	
	if dash_count <= 0:
		dash_in_cooldown = true
		dash_cooldown.start()
	
	# Dash camera effects
	if camera.has_method("shake"):
		camera.shake(1.3)

func _update_dash(delta: float) -> void:
	velocity = dash_direction * dash_speed
	dash_timer -= delta
	
	if dash_timer <= 0.0:
		is_dashing = false

func _handle_sliding(delta: float) -> void:
	if not is_sliding:
		return
	
	if not direction.x:
		_force_end_slide(delta)
		return
	
	_update_slide(delta)

func _force_end_slide(delta: float) -> void:
	var capsule = collision_shape.shape
	capsule.height = original_collision_height
	collision_shape.position.y = 0
	head.position.y = init_head_y
	is_sliding = false

func _update_slide(delta: float) -> void:
	velocity = direction * (dash_speed / 1.5)
	slide_timer -= delta
	
	var capsule = collision_shape.shape
	capsule.height = slide_collision_height
	collision_shape.position.y = - (original_collision_height - slide_collision_height) / 2
	
	if camera.has_method("shake"):
		camera.shake(0.5)

func _handle_normal_movement(delta: float) -> void:
	if is_dashing or is_sliding:
		return
	
	_reset_camera_effects(delta)
	
	if direction:
		_move_player(delta)
		_apply_walking_effects()
	else:
		_stop_player(delta)

func _reset_camera_effects(delta: float) -> void:
	head.rotation.z = head_z_init

func _move_player(delta: float) -> void:
	init_hand_z = hand.position.z
	init_eyeballhand_z = eyeball_hand.position.z
	
	var target_velocity = direction * SPEED
	velocity.x = lerp(velocity.x, target_velocity.x, 8 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 8 * delta)

func _apply_walking_effects() -> void:
	sinn += 0.1
	
	if is_on_floor():
		_apply_head_bob()
		_apply_hand_sway()

func _apply_head_bob() -> void:
	camera.rotation.x += sin(sinn) / 800
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _apply_hand_sway() -> void:
	# Apply sway relative to base position to work with recoil
	var sway_offset = Vector3(
		0,
		-sin(sinn) / 1500,
		0
	)
	
	var rotation_sway = Vector3(
		0,
		sin(sinn) / 200,
		0
	)
	rotation_sway.y = clamp(rotation_sway.y, deg_to_rad(-60), deg_to_rad(60))
	
	# Apply sway on top of recoil
	hand.position = hand_base_position + hand_current_recoil + sway_offset
	hand.rotation = hand_base_rotation + hand_current_recoil * 0.5 + rotation_sway
	
	eyeball_hand.position.y -= sin(sinn) / 1500

func _stop_player(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 10 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10 * delta)

# === ENHANCED SHOOTING SYSTEM ===
func shoot() -> void:
	var target_pos = get_crosshair_target()
	var muzzle_pos = shoot_point.global_position
	var shoot_direction = (target_pos - muzzle_pos).normalized()
	
	spawn_bullet(muzzle_pos, shoot_direction)
	_apply_gun_recoil()  # Apply recoil after shooting

func get_crosshair_target() -> Vector3:
	var viewport = get_viewport()
	var screen_center = viewport.get_visible_rect().size / 2
	
	var from = camera.project_ray_origin(screen_center)
	var to = from + camera.project_ray_normal(screen_center) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	return result.position if result else to

func spawn_bullet(start_pos: Vector3, shoot_direction: Vector3) -> void:
	var bullet = bullet_scene.instantiate()
	
	if bullets:
		bullets.add_child(bullet)
	else:
		get_tree().current_scene.add_child(bullet)
	
	bullet.global_position = start_pos
	bullet.initialize_bullet(shoot_direction)

# === SIGNAL HANDLERS ===
func _on_dash_countdown_timeout() -> void:
	if hp <= 0:
		return
	
	dash_count = MAX_DASHES
	dash_in_cooldown = false
	dash_cooldown.stop()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if hp <= 0 or not is_slaming:
		return
	
	if body.name == "slam_ground_body":
		body.fall()
	
	if camera.has_method("shake"):
		camera.shake(1.8)
	await get_tree().create_timer(0.3).timeout
	can_slam = false
	is_slaming = false

func _on_area_3d_area_entered(area: Area3D) -> void:
	if not area.is_in_group("slam_area") or not is_slaming:
		return
	
	area.get_parent().kill()
	velocity.y = JUMP_VELOCITY
	if camera.has_method("shake"):
		camera.shake(2)
	is_slaming = false
