extends Area2D

@export_category( "pathfinding connectic")
@export var movementControler : CMP_Movement = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#a body that enter is an ennemy
func _on_body_entered(body):
	
	if (movementControler.currentTarget != null) :
		
		# check if the new body is closer to the current body 
		var d1 = position.distance_to(body.position)
		var d2 = position.distance_to(movementControler.currentTarget.position)
		
		if !(d1 > d2) : return
	
	movementControler.currentTarget = body
	pass # Replace with function body.
