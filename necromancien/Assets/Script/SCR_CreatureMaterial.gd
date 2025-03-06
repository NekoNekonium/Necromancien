extends "res://Assets/Script/SCR_Parent_interactible.gd"
class_name CMP_CreatureMaterial


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func is_pressed() :
	
	print("is pressed")
	
	GlbScrPlayerData.composants += 1
	
	pass
