extends CharacterBody3D

var GRAVITY = 0.0
const MAX_VEL = -100.0
var fallen = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
func _physics_process(delta: float) -> void:
	if is_on_floor():
		$"../Player/head/Camera3D".shake(1.8)
	velocity.y -= GRAVITY * delta
	velocity.y = clamp(velocity.y, MAX_VEL, 0)
	move_and_slide()

func fall():
	GRAVITY = 30.0
	fallen = true
