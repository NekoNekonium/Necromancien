extends Node
class_name CMP_vie

@export var Max_life : int = 1
var life : int = Max_life

func changeLife(Mod : int, Attack : bool) -> void:
	
	life += Mod
	
	if (life > Max_life):
		
		life = Max_life
	if (life <= 0):
		
		dead.emit()
		pass
	
	return


signal dead()
