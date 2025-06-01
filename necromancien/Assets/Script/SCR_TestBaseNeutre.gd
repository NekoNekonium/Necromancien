extends Node2D

@onready var base_neutre = $BaseNeutre
@onready var label_instructions = $LabelInstructions

func _ready():
	print("Test Base Neutre démarré")
	
	# Configurer la base neutre
	if base_neutre:
		base_neutre.set_ally_with_player(false)  # Neutre au début
		print("Base neutre configurée")

func _process(delta):
	# Mettre à jour les infos à l'écran
	if base_neutre and label_instructions:
		var scout_count = base_neutre.get_scout_count()
		var alert_level = base_neutre.get_alert_level()
		var faction = base_neutre.get_faction_name()
		
		label_instructions.text = "🏛️ BASE NEUTRE - " + faction + "\n"
		label_instructions.text += "🦌 Scouts déployés: " + str(scout_count) + "\n"
		label_instructions.text += "⚠️ Niveau d'alerte: " + str(alert_level) 
