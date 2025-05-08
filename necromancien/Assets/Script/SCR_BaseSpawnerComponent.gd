extends "res://Assets/Script/SCR_Parent_interactible.gd"
class_name CMP_CreatureSpawner

@export_category("General data")
@export var creatureCost : int = 1
@export var spawnedCreature : PackedScene 

@export_category("IsEnnemy")
@export var isEnnemy := false

@export_category("automation data")
#activate Automation
@export var automation : bool = false
@export var automationTime : float = 10




# Called when the node enters the scene tree for the first time.
func _ready():
	
	if automation == true : 
		$AutomationTimer.wait_time = automationTime
		$AutomationTimer.start()
	
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
	
	newMob.position = global_position
	
	#doit attacher au parent du parent
	get_parent().get_parent().add_child.call_deferred(newMob)
	


func _on_automation_timer_timeout():
	
	if (GlbScrPlayerData.composants >= creatureCost) :
		
		GlbScrPlayerData.composants -=  creatureCost
		SpawnMob()
	
	pass # Replace with function body.
