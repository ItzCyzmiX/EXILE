extends Camera3D

var shake_strength := 0.0
var shake_decay := 5.0
var shake_max_offset := Vector3(0.1, 0.1, 0.0)  # How far it can shake per axis
var original_position := Vector3.ZERO
var time = 0
var shake_freq = 3
func _ready():
	original_position = position

func _process(delta):
	if shake_strength > 0:
		var offset = Vector3(
			randf_range(-1, 1) * shake_strength * shake_max_offset.x,
			randf_range(-1, 1) * shake_strength * shake_max_offset.y,
			randf_range(-1, 1) * shake_strength * shake_max_offset.z
		)
		position = original_position + offset
		shake_strength = max(shake_strength - shake_decay * delta, 0.0)
		
	else:
		position = original_position

func shake(amount: float):
	shake_strength = amount
	
