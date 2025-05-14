extends Node
class_name CMP_spell_project

#un lien avec les composants présents, pour ne pas avoir a les charger a runtime
@export_category("composants")

#dans le cas de figure où une variable est nulle, on ignore toute les actions qui lui sont demander
@export var targeting : CMP_Targeting
@export var effect : CMP_SpellEffectsParents

#les créatures affecter 
var AffectedTargets : Array[Node2D]


# le final spot 
var finalLocation : Vector2

###### FONCTIONS ########
func ReceiveInputStart():
	
	#si le targeting prends une location, appeler l'effet avec une location
	if (targeting.spellTargetMode == targeting.TargetMode.area):
		
		get_parent().SetSpellEffectArea(targeting.spellAreaSize, 1)
		
		
	
	AffectedTargets = get_parent().SpellArea.get_parent().get_overlapping_bodies()
	
	effect.selectTargets(AffectedTargets)
	
	pass

func ReceiveInputHeld():
	
	pass

func ReceiveInputRelease():
	
	finalLocation = get_cursor().global_position
	
	effect.start_effect(finalLocation, null)
	
	pass


func get_cursor() -> Node2D:
	
	return get_parent().get_parent()
