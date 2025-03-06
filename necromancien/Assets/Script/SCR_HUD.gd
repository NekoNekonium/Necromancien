extends Control

#reference au widget qui indique le nombre de materiaux
@export var ComposantLabel : Label

#reference au widget qui indique la quantité de mana
@export var ManaLabel : Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if (ComposantLabel != null):
		
		ComposantLabel.text = str(GlbScrPlayerData.composants)
	
	if (ManaLabel != null):
		
		ManaLabel.text = str(GlbScrPlayerData.mana)
	
	pass
