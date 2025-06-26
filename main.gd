extends Node3D

var cur_lvl = 1
@onready var world = $world
func _ready() -> void:
	var level = load("res://levels/level_" + str(cur_lvl) + ".tscn").instantiate()
	var player = preload("res://player.tscn").instantiate()
	player.position = level.get_node("player_spawn").position 
	player.get_node("head").rotation = level.get_node("player_spawn").rotation 
	world.add_child(level)
	world.add_child(player)	
func _unhandled_input(event: InputEvent) -> void:
		
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.is_pressed():
	
		get_tree().quit()
