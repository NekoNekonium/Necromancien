extends CMP_SpellEffectsParents
class_name SpellEffect_projection


var actorList

func start_effect(position : Vector2, actor : Node2D) :
	
	var modif = Vector2(randf_range(-2,2), randf_range(-2,2))
	
	for m in actorList :
		
		
		
		m.position = position + modif
		
		modif = Vector2(randf_range(-2,2), randf_range(-2,2))
		
		m.get_child(0).locked = false
	
	pass

func selectTargets(list : Array[Node2D]):
	
	
	for m in list :
		
		m.get_child(0).locked = true
		
		m.position = Vector2(-1000,-1000)
		
	
	actorList = list
	
	
	pass
