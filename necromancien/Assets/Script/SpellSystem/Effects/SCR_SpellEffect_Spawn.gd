extends CMP_SpellEffectsParents
class_name SpellEffect_Spawn

@export var spawnedScene : PackedScene


func start_effect(position : Vector2, actor : Node2D) :
	
	var n = spawnedScene.instantiate()
	
	get_tree().root.get_child(0).add_child(n)
	n.position = position
	
	pass
