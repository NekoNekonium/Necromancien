extends Node

#variable for selecting the spell
var spellIndex : int = 0
var maxSpells : int = 0


@export var SpellArea : CollisionShape2D

func _ready():
	maxSpells = get_child_count()

#get the inputs to change the selected spell
func _input(event):
	if (maxSpells == 0 ) : return
	
	
	if (event.is_action_pressed("ScrollUp")) :
		spellIndex = (spellIndex + 1) % maxSpells
		pass
	elif (event.is_action_pressed("ScrollDown")):
		spellIndex = spellIndex - 1
		if (spellIndex < 0) : spellIndex = maxSpells - 1
		pass
	
	pass

func SetSpellEffectArea(SpellRange : float, filterMode : int ):
	
	SpellArea.shape.radius = SpellRange
	
	if (filterMode == 0) :
		
		pass
	elif (filterMode == 1) :
		$"../SpellEffectArea".set_collision_layer_value(1, false)
		$"../SpellEffectArea".set_collision_layer_value(2, true)
		$"../SpellEffectArea".set_collision_layer_value(3, false)
		$"../SpellEffectArea".set_collision_mask_value(1, false)
		$"../SpellEffectArea".set_collision_mask_value(2, true)
		$"../SpellEffectArea".set_collision_mask_value(3, false)
		pass
	elif (filterMode == 2):
		
		pass
	
	pass

func get_overlaping_Characters ():
	
	return $"../SpellEffectArea".get_overlapping_bodies()
	
