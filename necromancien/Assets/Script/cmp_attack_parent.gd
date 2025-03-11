extends Area2D
class_name CMP_Attack_parent

@export_category("aggro system")
@export var aggroRange : float = 20
@export_range(1,4) var TrackedCollision : int = 3 #0 for items, 1 for allies, 2 for ennemis, 3 for targetable
@export_range(0.5, 5) var aggroCheckCooldown : float = 1 #the time between two check of aggro


# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_collision_layer_value(TrackedCollision, true)
	set_collision_mask_value(TrackedCollision, true)
	
	$ActivationRange.shape.radius = aggroRange
	
	

#to modify in child 
func LaunchAttack():
	
	print("attack !")
	
	for t in get_overlapping_bodies() :
		
		var lifeNode = null
		
		for n in t.get_children() :
			if n.name == "CmpVie" :
				print ("correct life node")
				lifeNode = n
				break
			
		
		if (lifeNode != null):
			
			lifeNode.changeLife(-2, true)
			
		else :
			
			t.call_deferred("queue_free")
			
		
		pass
	
	pass


func _on_attack_timer_timeout():
	
	#if there is at least one valid target
	if (get_overlapping_bodies().size() > 0):
		
		#launch attack (will depend on the actual attack class
		LaunchAttack()
		pass
	pass # Replace with function body.
