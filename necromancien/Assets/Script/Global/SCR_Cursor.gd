extends Area2D

var currentTarget : Node = null


# Called when the node enters the scene tree for the first time.
func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	
	pass


func _input(event):
	if event is InputEventMouseMotion:
		position = event.position
	
	if event.is_action_pressed("Click"):
		
		$AnimationPlayer.play("OnClick")
		ClickAction()
	

func ClickAction():
	print (GlbScrPlayerData.cible)
	if (currentTarget != null):
		
		if (currentTarget.is_in_group("Destination")) :
			
			GlbScrPlayerData.cible = currentTarget
			
			
			
			return
		
		
		currentTarget.is_pressed()
	
	pass


# Lancer quand cela detecte un interactible
func _on_area_entered(area):
	
	currentTarget = area
	pass # Replace with function body.

#nettoye la cible actuel si elle n'est plus sous le curseur
func _on_area_exited(area):
	if (area == currentTarget):
		currentTarget = null
	pass # Replace with function body.
