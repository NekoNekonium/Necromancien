extends Node
class_name CMP_vie

@export var Max_life : int = 1
var life : int = Max_life

func _ready():
	life = Max_life

func changeLife(Mod : int, Attack : bool) -> void:
	
	life += Mod
	
	
	if (life > Max_life):
		
		life = Max_life
		
		
	if (life <= 0):
		
		dead.emit()
		
		##temporary direct removal
		get_parent().call_deferred("queue_free")
		pass
	
	return


signal dead()
