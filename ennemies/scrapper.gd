extends CharacterBody3D

var hp = 3
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var player = $"../Player"
@onready var slam_area = $scrapper_area
@onready var death_particles = $death_particle
@onready var model = $Armature
var ded = false
var spawn_pos = null
func _ready() -> void:
	death_particles.emitting = false
	spawn_pos  =position
	$AnimationPlayer.play("walk", -1, 2.0)
func _physics_process(delta: float) -> void:
	
	if hp<=0:
		kill()
		return
		
	if position.y == player.position.y:
		position.x += 10
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player == null:
		return

	var direction = (player.global_transform.origin - global_transform.origin)
	direction.y = 0  # Ignore vertical movement
	direction = direction.normalized()

	velocity = direction * SPEED
	move_and_slide()

func deal_weak_point_dmg():
	hp -= 2

func kill():
	hp = 0
	death_particles.emitting = true
	remove_child(slam_area)
	remove_child($Armature)
	remove_child($CollisionShape3D2)
	remove_child($CollisionShape3D3)
	remove_child($CollisionShape3D)
	remove_child($OmniLight3D)
	remove_child($scrapper_area)

func _on_scrapper_arsea_body_entered(body: Node3D) -> void:
	if body.name == "slam_ground_body" and body.fallen:
		kill()


func _on_death_particle_finished() -> void:
	queue_free()
