extends Control

@onready var right = $TextureRect
@onready var left = $TextureRect2
var tween = Tween.new()

var init_right_x = 0.0
var init_left_x = 0.0

func _ready() -> void:
	left.position.x -= 32
	right.position.x +=32
