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
		ClickAction(inputType.clicked)
	
	
	if (event.is_action("RightClick")):
		
		if (event.is_action_pressed("RightClick")):
			ClickAction_right(inputType.clicked)
			
			pass
		elif (event.is_action_released("RightClick")) :
			
			ClickAction_right(inputType.release)
			pass
		else : 
			
			ClickAction_right(inputType.held)
			
		
		
		pass
	
	


#enum qui indique si l'action est click, held, ou release
enum inputType {clicked, held, release}

func ClickAction_right(type : inputType):
	
	if (type == inputType.clicked) :
		$CmpSpellManager.get_child($CmpSpellManager.spellIndex).ReceiveInputStart()
		pass
	
	if (type == inputType.held):
		$CmpSpellManager.get_child($CmpSpellManager.spellIndex).ReceiveInputHeld()
		pass
	
	if (type == inputType.release):
		$CmpSpellManager.get_child($CmpSpellManager.spellIndex).ReceiveInputRelease()
		
		pass
	

func ClickAction(type : inputType):
	if (currentTarget != null):
		
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


func _on_body_entered(body):
	currentTarget = body
	pass # Replace with function body.


func _on_body_exited(body):
	if (body == currentTarget):
		currentTarget = null
	pass # Replace with function body.
