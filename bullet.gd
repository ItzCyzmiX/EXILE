extends RigidBody3D

@onready var ray = $RayCast3D
@onready var area = $Area3D
var direction: Vector3 = Vector3.ZERO
var initialized: bool = false
var velocity = Vector3.ZERO
const speed := 50.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_scale = 0

func initialize_bullet(shoot_direction: Vector3):
	direction = shoot_direction.normalized()
	initialized = true
	
	# Point the bullet in the direction it's traveling
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.DOWN)

func _physics_process(delta: float) -> void:
	if not initialized:
		return
	
	# Move bullet forward using velocity
	linear_velocity = direction * speed
	
	# Check for overlapping areas (existing functionality)
	if area:
		
		for i in area.get_overlapping_areas():
			
			if i.is_in_group("weak_point"):
				
				i.get_parent().deal_weak_point_dmg()
				$break.emitting = true 
				remove_child(area)
				
				


func _on_area_3d_body_entered(body: Node3D) -> void:
	$break.emitting = true 


func _on_break_finished() -> void:
	queue_free()
