extends "res://Assets/Script/SCR_Parent_interactible.gd"
class_name CMP_CreatureMaterial

@export_category("Automation")

@export var autoharvest_wait : float = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	if (autoharvest_wait > 0):
		$Timer.wait_time = autoharvest_wait
		$Timer.start()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func is_pressed() :
	
	print("is pressed")
	
	GlbScrPlayerData.composants += 1
	
	pass


func _on_timer_timeout():
	
	GlbScrPlayerData.composants += 1
	
	pass # Replace with function body.
