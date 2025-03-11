extends "res://Assets/Script/SCR_Parent_interactible.gd"
class_name CMP_CreatureSpawner

@export var creatureCost : int = 1
@export var spawnedCreature : PackedScene 


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func is_pressed() :
	
	if (GlbScrPlayerData.composants >= creatureCost) :
		
		GlbScrPlayerData.composants -=  creatureCost
		SpawnMob()
	
	pass


func SpawnMob():
	
	
	
	var newMob = spawnedCreature.instantiate()
	
	if (GlbScrPlayerData.cible == null):
		
		#newMob.get_child(0).destination = self
		print ("spawn error")
	else :
		
		#newMob.get_child(0).destination = GlbScrPlayerData.cible
		print ("correct Spawn")
		
	newMob.position = global_position
	
	#doit attacher au parent du parent
	get_parent().get_parent().add_child.call_deferred(newMob)
	
