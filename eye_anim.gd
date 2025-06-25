extends MeshInstance3D

@onready var eye_bulbe = $Sphere_002
@onready var pupil = $Sphere_003

var sinn=0
var max_size = 0
var size = -0.015
var max_pupil_size = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	max_size = eye_bulbe.scale.y 
	max_pupil_size = pupil.scale.y

func _process(delta: float) -> void:
	
	eye_bulbe.scale.y += size
	
	if eye_bulbe.scale.y>=max_size or eye_bulbe.scale.y<=0:
		size = -size
		
		
	if eye_bulbe.scale.y <= max_size/2:
		if eye_bulbe.scale.y > 0:
			pupil.scale.y -= -size/2
		else:
			pupil.scale.y += -size/2
	
	pupil.scale.y = clamp(pupil.scale.y, 0, max_pupil_size)
