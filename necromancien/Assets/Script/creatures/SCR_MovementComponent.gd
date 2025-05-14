extends Node2D
class_name CMP_Movement

#Refference to other nodes
@export_category("references to other nodes")
@export var navigationComponent : NavigationAgent2D

@export_category("Movement statistics")
@export var speed : float = 100

# additional movement effects
var randDirOffset : Vector2 = Vector2(0,0)
var ChangeVectorTimer : float = 0

@export_category("Faction")
@export var ennemy : bool = false

# variables used in targeting
var currentTarget = null

var locked : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	ChangeVectorTimer = randf_range(1, 5)
	randDirOffset = Vector2(randf_range(-1,1), randf_range(-1,1))
	
	if (ennemy) :
		if(GlbScrPlayerData.PlayerBase == null):return
		navigationComponent.target_position = GlbScrPlayerData.PlayerBase.position
	else : 
		if(GlbScrPlayerData.cible == null):return
		navigationComponent.target_position = GlbScrPlayerData.cible
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (locked) : return
	
	
	if (currentTarget == null):
		if (ennemy) :
			if(GlbScrPlayerData.PlayerBase == null):return
			navigationComponent.target_position = GlbScrPlayerData.PlayerBase.position
		else : 
			if(GlbScrPlayerData.cible == null):return
			navigationComponent.target_position = GlbScrPlayerData.cible
		
	else : 
		
		navigationComponent.target_position = currentTarget.position
		
	
	ChangeVectorTimer -= delta
	if (ChangeVectorTimer <= 0):
		randDirOffset = Vector2(randf_range(-1,1), randf_range(-1,1))
		ChangeVectorTimer = randf_range(1, 5)
	
	
	var nextPath = navigationComponent.get_next_path_position()
	
	if get_parent() is CharacterBody2D :
		
		get_parent().velocity = ((nextPath - get_parent().position).normalized() +  (randDirOffset / 4)).normalized() * speed
		get_parent().move_and_slide()
		if (get_parent().velocity.length() > 0) :
			get_parent().look_at(get_parent().position + get_parent().velocity.normalized())
		
	
	pass
