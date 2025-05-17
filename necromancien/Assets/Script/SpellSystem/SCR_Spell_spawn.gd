extends Node
class_name CMP_spell_spawn

#un lien avec les composants présents, pour ne pas avoir a les charger a runtime
@export_category("composants")

#dans le cas de figure où une variable est nulle, on ignore toute les actions qui lui sont demander
@export var targeting : CMP_Targeting
@export var effect : CMP_SpellEffectsParents


###### FONCTIONS ########
func ReceiveInputStart():
	
	#si le targeting prends une location, appeler l'effet avec une location
	if (targeting.spellTargetMode == targeting.TargetMode.location):
		
		effect.start_effect(get_cursor().position, null)
		
	
	pass

func ReceiveInputHeld():
	
	pass

func ReceiveInputRelease():
	
	pass


func get_cursor() -> Node2D:
	
	return get_parent().get_parent()
