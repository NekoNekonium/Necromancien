extends CharacterBody2D
class_name AmeVillageoise

# =============================================================================
# PROPRIÉTÉS SPÉCIALES DE L'ÂME VILLAGEOISE
# =============================================================================

@export_category("Capacités Spéciales")
@export var peut_traverser_murs: bool = true
@export var duree_phase: float = 3.0
@export var vitesse_reduite_en_phase: float = 0.3

@export_category("Comportement Défensif")
@export var zone_protection: float = 150.0
@export var priorite_defense: bool = true

# =============================================================================
# VARIABLES INTERNES
# =============================================================================

var en_mode_phase: bool = false
var collision_normale: int
var collision_mask_normale: int
var cibles_a_proteger: Array = []
var vitesse_originale: float = 100.0

# Références aux composants
@onready var movement_component = $CMP_movement
@onready var aggression_manager = $CmpAgressionManager
@onready var phase_timer = $PhaseTimer
@onready var sprite_corps = $SpriteCorps

# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	# Sauvegarder les collisions normales
	collision_normale = collision_layer
	collision_mask_normale = collision_mask
	
	# Sauvegarder la vitesse originale
	if movement_component:
		vitesse_originale = movement_component.speed
	
	# Connecter le timer pour sortir du mode phase
	phase_timer.timeout.connect(_sortir_mode_phase)
	
	# Ajouter à la base de données des unités défensives
	add_to_group("Defenseurs")
	add_to_group("Destination")
	
	# Configuration initiale
	_configurer_apparence()
	_detecter_cibles_a_proteger()

func _configurer_apparence():
	# Effet semi-transparence spectrale
	sprite_corps.modulate = Color(0.7, 0.9, 1.0, 0.6)
	
	# Animation de flottement
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite_corps, "position:y", -2.0, 1.0)
	tween.tween_property(sprite_corps, "position:y", 2.0, 1.0)

# =============================================================================
# CAPACITÉ SPÉCIALE : TRAVERSER LES MURS
# =============================================================================

func entrer_mode_phase():
	if en_mode_phase or not peut_traverser_murs:
		return
	
	print("Âme Villageoise: Mode phase activé !")
	en_mode_phase = true
	
	# Désactiver les collisions physiques
	collision_layer = 0
	collision_mask = 0
	
	# Réduire la vitesse
	if movement_component:
		movement_component.speed = vitesse_originale * vitesse_reduite_en_phase
	
	# Effet visuel de phase
	sprite_corps.modulate = Color(0.5, 0.7, 1.0, 0.3)
	
	# Démarrer le timer
	phase_timer.wait_time = duree_phase
	phase_timer.start()

func _sortir_mode_phase():
	if not en_mode_phase:
		return
	
	print("Âme Villageoise: Fin du mode phase")
	en_mode_phase = false
	
	# Restaurer les collisions
	collision_layer = collision_normale
	collision_mask = collision_mask_normale
	
	# Restaurer la vitesse
	if movement_component:
		movement_component.speed = vitesse_originale
	
	# Restaurer l'apparence
	sprite_corps.modulate = Color(0.7, 0.9, 1.0, 0.6)

# =============================================================================
# COMPORTEMENT DÉFENSIF
# =============================================================================

func _detecter_cibles_a_proteger():
	# Rechercher les alliés dans la zone de protection
	cibles_a_proteger.clear()
	
	var allies = get_tree().get_nodes_in_group("Destination")
	for allie in allies:
		if allie != self and global_position.distance_to(allie.global_position) <= zone_protection:
			cibles_a_proteger.append(allie)

func _process(delta):
	if priorite_defense:
		_gerer_defense()
	
	# Vérifier si on doit activer le mode phase en cas de danger
	_verifier_activation_phase()

func _gerer_defense():
	# Mise à jour périodique des cibles à protéger
	_detecter_cibles_a_proteger()
	
	# Si un allié est en danger, se diriger vers lui
	for cible in cibles_a_proteger:
		if _allie_en_danger(cible):
			_proteger_allie(cible)
			break

func _allie_en_danger(allie) -> bool:
	# Vérifier s'il y a des ennemis près de l'allié
	var ennemis = get_tree().get_nodes_in_group("EnnemyBase")
	for ennemi in ennemis:
		if allie.global_position.distance_to(ennemi.global_position) < 80:
			return true
	return false

func _proteger_allie(allie):
	if movement_component and aggression_manager:
		# Se positionner entre l'allié et le danger
		var direction_protection = (global_position - allie.global_position).normalized()
		var position_protection = allie.global_position + direction_protection * 30
		
		# Utiliser le système de navigation existant
		GlbScrPlayerData.cible = allie

func _verifier_activation_phase():
	# Activer automatiquement le mode phase si encerclé
	if not en_mode_phase:
		var ennemis_proches = _compter_ennemis_proches()
		if ennemis_proches >= 3:  # Si 3+ ennemis autour
			entrer_mode_phase()

func _compter_ennemis_proches() -> int:
	var count = 0
	var ennemis = get_tree().get_nodes_in_group("EnnemyBase")
	for ennemi in ennemis:
		if global_position.distance_to(ennemi.global_position) < 60:
			count += 1
	return count

# =============================================================================
# GESTION DES DÉGÂTS
# =============================================================================

func _on_cmp_vie_death():
	# Effet de disparition spectrale
	var tween = create_tween()
	tween.parallel().tween_property(sprite_corps, "modulate:a", 0.0, 1.0)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 1.0)
	tween.tween_callback(queue_free)

# =============================================================================
# FONCTIONS PUBLIQUES POUR L'IA
# =============================================================================

func forcer_mode_phase():
	"""Fonction pour activer manuellement le mode phase"""
	entrer_mode_phase()

func est_en_mode_phase() -> bool:
	return en_mode_phase

func get_cibles_protegees() -> Array:
	return cibles_a_proteger 