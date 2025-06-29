extends Node3D

var cur_lvl = 1
@onready var health_bar = $CanvasLayer/TextureProgressBar
@onready var dashes_ui = $CanvasLayer/Control
@onready var world = $world
var player = null
func _ready() -> void:
	var level = load("res://levels/level_" + str(cur_lvl) + ".tscn").instantiate()
	player = level.get_node("Player")
	world.add_child(level)

func _process(delta: float) -> void:
	if player.hp>0:
		for i in range(3):
			dashes_ui.get_child(i).texture = preload("res://ui/dash_empty.png")
			
		for i in range(player.dash_count):
			dashes_ui.get_child(i).texture = preload("res://ui/dash_full.png")
		
		health_bar.value = player.hp
func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
	
		get_tree().quit()
