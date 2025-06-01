extends CharacterBody2D
class_name GardeSanglier

# =============================================================================
# PROPRIÉTÉS DU GARDE-SANGLIER
# =============================================================================

@export_category("Capacités de Tank")
@export var vitesse_base: float = 80.0
@export var vitesse_charge: float = 250.0
@export var force_charge: float = 3.0
@export var resistance_base: float = 0.2

@export_category("Système de Charge")
@export var distance_charge: float = 200.0
@export var duree_preparation: float = 1.5
@export var duree_charge: float = 2.0
@export var cooldown_charge: float = 8.0

@export_category("Mode Défensif")
@export var peut_bloquer: bool = true
@export var reduction_degats_bloc: float = 0.5
@export var duree_bloc: float = 5.0
@export var regeneration_bloc: float = 1.0

@export_category("Résistance")
@export var resistance_magique: float = 0.3
@export var resistance_physique: float = 0.4
@export var immunite_projection: bool = true

# =============================================================================
# VARIABLES INTERNES
# =============================================================================

# État de charge
var en_preparation_charge: bool = false
var en_charge: bool = false
var cible_charge: Node2D = null
var direction_charge: Vector2
var temps_charge_restant: float = 0.0

# État défensif
var en_mode_bloc: bool = false
var temps_bloc_restant: float = 0.0
var peut_charger: bool = true

# Résistance active
var bonus_resistance: float = 0.0
var immunite_active: bool = false

# Statistiques
var charges_effectuees: int = 0
var degats_bloques: float = 0.0
var ennemis_percutes: int = 0

# Références aux composants
@onready var movement_component = $CMP_movement
@onready var aggression_manager = $CmpAgressionManager
@onready var charge_detection = $ChargeDetection
@onready var charge_timer = $ChargeTimer
@onready var defense_timer = $DefenseTimer
@onready var resistance_timer = $ResistanceTimer
@onready var sprite_corps = $SpriteCorps
@onready var sprite_yeux = $SpriteYeux
@onready var sprite_yeux2 = $SpriteYeux2
@onready var charge_line = $ChargeLine
@onready var effet_charge = $EffetCharge
@onready var sprite_bouclier = $SpriteCorps/SpriteBouclier
@onready var sprite_defenses = $SpriteCorps/SpriteDefenses
@onready var sprite_defenses2 = $SpriteCorps/SpriteDefenses2

# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	# Connecter les signaux
	charge_detection.body_entered.connect(_on_ennemi_detecte_pour_charge)
	charge_timer.timeout.connect(_evaluer_charge)
	defense_timer.timeout.connect(_desactiver_mode_bloc)
	resistance_timer.timeout.connect(_fin_resistance_temporaire)
	
	# Ajouter aux groupes
	add_to_group("Tanks")
	add_to_group("GardesSanglier")
	add_to_group("Destination")
	
	# Configuration initiale
	_configurer_apparence_sanglier()
	_ajuster_vitesse_tank()
	
	print("Garde-Sanglier déployé - Faction: Serviteurs des Ogres")

func _configurer_apparence_sanglier():
	# Couleur brun-roux du sanglier
	sprite_corps.modulate = Color(0.4, 0.3, 0.2, 1.0)
	
	# Yeux rouges agressifs
	sprite_yeux.modulate = Color(0.8, 0.2, 0.1, 1.0)
	sprite_yeux2.modulate = Color(0.8, 0.2, 0.1, 1.0)
	
	# Défenses en ivoire
	sprite_defenses.modulate = Color(0.8, 0.7, 0.6, 1.0)
	sprite_defenses2.modulate = Color(0.8, 0.7, 0.6, 1.0)
	
	# Animation de respiration lourde
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite_corps, "scale", Vector2(0.062, 0.058), 2.0)
	tween.tween_property(sprite_corps, "scale", Vector2(0.06, 0.06), 2.0)

func _ajuster_vitesse_tank():
	if movement_component:
		movement_component.speed = vitesse_base

# =============================================================================
# SYSTÈME DE CHARGE PUISSANTE
# =============================================================================

func _on_ennemi_detecte_pour_charge(ennemi):
	if not _est_ennemi(ennemi) or not peut_charger or en_charge:
		return
	
	var distance = global_position.distance_to(ennemi.global_position)
	if distance > 50 and distance <= distance_charge:
		_preparer_charge(ennemi)

func _est_ennemi(body) -> bool:
	return body.collision_layer & 4 != 0

func _evaluer_charge():
	if en_charge or en_preparation_charge:
		return
	
	# Chercher des ennemis à charger
	var ennemis_detectes = []
	var corps_detectes = charge_detection.get_overlapping_bodies()
	
	for corps in corps_detectes:
		if _est_ennemi(corps):
			var distance = global_position.distance_to(corps.global_position)
			if distance > 50 and distance <= distance_charge:
				ennemis_detectes.append(corps)
	
	if ennemis_detectes.size() > 0:
		# Choisir l'ennemi le plus proche
		var cible_optimale = ennemis_detectes[0]
		var distance_min = global_position.distance_to(cible_optimale.global_position)
		
		for ennemi in ennemis_detectes:
			var dist = global_position.distance_to(ennemi.global_position)
			if dist < distance_min:
				distance_min = dist
				cible_optimale = ennemi
		
		_preparer_charge(cible_optimale)

func _preparer_charge(cible: Node2D):
	if en_charge or en_preparation_charge:
		return
	
	en_preparation_charge = true
	cible_charge = cible
	peut_charger = false
	
	print("Garde-Sanglier: Préparation de charge vers ", cible.name)
	
	# Calculer direction de charge
	direction_charge = (cible.global_position - global_position).normalized()
	
	# Effet visuel de préparation
	_effet_preparation_charge()
	
	# Attendre puis charger
	await get_tree().create_timer(duree_preparation).timeout
	_executer_charge()

func _effet_preparation_charge():
	# Ligne de visée vers la cible
	charge_line.clear_points()
	charge_line.add_point(Vector2.ZERO)
	if cible_charge:
		charge_line.add_point(to_local(cible_charge.global_position))
	
	# Gratter le sol avant charge
	sprite_corps.modulate = Color(0.6, 0.3, 0.2, 1.0)
	sprite_yeux.modulate = Color(1.0, 0.1, 0.0, 1.0)
	sprite_yeux2.modulate = Color(1.0, 0.1, 0.0, 1.0)
	
	# Particules de préparation
	effet_charge.emitting = true

func _executer_charge():
	if not en_preparation_charge or not is_instance_valid(cible_charge):
		_annuler_charge()
		return
	
	en_preparation_charge = false
	en_charge = true
	temps_charge_restant = duree_charge
	charges_effectuees += 1
	
	print("Garde-Sanglier: CHARGE ! Vers ", cible_charge.global_position)
	
	# Boost de vitesse pour la charge
	if movement_component:
		movement_component.speed = vitesse_charge
	
	# Désactiver la navigation normale et forcer la direction
	_forcer_direction_charge()
	
	# Effet visuel de charge
	sprite_corps.modulate = Color(0.8, 0.4, 0.2, 1.0)
	effet_charge.amount = 30
	
	# Timer pour fin de charge
	await get_tree().create_timer(duree_charge).timeout
	_terminer_charge()

func _forcer_direction_charge():
	# Calculer la position de destination
	var distance_charge_max = distance_charge * 1.5
	var destination = global_position + direction_charge * distance_charge_max
	
	# Forcer la navigation vers cette destination
	if movement_component and movement_component.navigationComponent:
		movement_component.navigationComponent.target_position = destination

func _terminer_charge():
	en_charge = false
	temps_charge_restant = 0.0
	
	# Restaurer vitesse normale
	if movement_component:
		movement_component.speed = vitesse_base
	
	# Restaurer apparence
	sprite_corps.modulate = Color(0.4, 0.3, 0.2, 1.0)
	sprite_yeux.modulate = Color(0.8, 0.2, 0.1, 1.0)
	sprite_yeux2.modulate = Color(0.8, 0.2, 0.1, 1.0)
	
	# Nettoyer effets visuels
	charge_line.clear_points()
	effet_charge.emitting = false
	effet_charge.amount = 20
	
	# Cooldown avant prochaine charge
	charge_timer.wait_time = cooldown_charge
	charge_timer.start()
	
	await charge_timer.timeout
	peut_charger = true
	
	print("Garde-Sanglier: Charge terminée, prêt pour la prochaine")

func _annuler_charge():
	en_preparation_charge = false
	en_charge = false
	peut_charger = true
	
	# Restaurer apparence normale
	sprite_corps.modulate = Color(0.4, 0.3, 0.2, 1.0)
	charge_line.clear_points()
	effet_charge.emitting = false

# =============================================================================
# SYSTÈME DÉFENSIF ET RÉSISTANCE
# =============================================================================

func activer_mode_bloc():
	if en_mode_bloc:
		return
	
	en_mode_bloc = true
	temps_bloc_restant = duree_bloc
	bonus_resistance += reduction_degats_bloc
	
	print("Garde-Sanglier: Mode défensif activé")
	
	# Effet visuel défensif
	sprite_bouclier.modulate = Color(0.8, 0.6, 0.3, 1.0)
	sprite_corps.modulate = Color(0.3, 0.25, 0.15, 1.0)
	
	# Ralentir légèrement
	if movement_component:
		movement_component.speed = vitesse_base * 0.7
	
	defense_timer.wait_time = duree_bloc
	defense_timer.start()

func _desactiver_mode_bloc():
	en_mode_bloc = false
	bonus_resistance -= reduction_degats_bloc
	
	# Restaurer vitesse normale
	if movement_component:
		movement_component.speed = vitesse_base
	
	# Restaurer apparence
	sprite_bouclier.modulate = Color(0.6, 0.5, 0.3, 0.8)
	sprite_corps.modulate = Color(0.4, 0.3, 0.2, 1.0)
	
	print("Garde-Sanglier: Fin du mode défensif")

func activer_resistance_temporaire():
	immunite_active = true
	bonus_resistance += 0.3
	
	# Effet visuel de résistance
	sprite_corps.modulate = Color(0.5, 0.4, 0.3, 1.0)
	
	resistance_timer.start()

func _fin_resistance_temporaire():
	immunite_active = false
	bonus_resistance -= 0.3
	sprite_corps.modulate = Color(0.4, 0.3, 0.2, 1.0)

# =============================================================================
# GESTION DES COLLISIONS ET DÉGÂTS
# =============================================================================

func _on_body_entered_during_charge(body):
	if en_charge and _est_ennemi(body):
		_percuter_ennemi(body)

func _percuter_ennemi(ennemi: Node2D):
	ennemis_percutes += 1
	print("Garde-Sanglier: Ennemi percuté - ", ennemi.name)
	
	# Infliger des dégâts de charge
	if ennemi.has_method("take_damage"):
		ennemi.take_damage(force_charge)
	
	# Effet de projection si possible
	if ennemi.has_method("apply_knockback") and not immunite_projection:
		var knockback_force = direction_charge * 100
		ennemi.apply_knockback(knockback_force)

# =============================================================================
# BOUCLE PRINCIPALE
# =============================================================================

func _process(delta):
	# Gestion des timers manuels
	if en_charge:
		temps_charge_restant -= delta
		if temps_charge_restant <= 0:
			_terminer_charge()
	
	if en_mode_bloc:
		temps_bloc_restant -= delta
		if temps_bloc_restant <= 0:
			_desactiver_mode_bloc()
	
	# Auto-activation du mode bloc si entouré
	_evaluer_activation_defense()
	
	# Régénération en mode bloc
	if en_mode_bloc:
		_regeneration_defensive(delta)

func _evaluer_activation_defense():
	if en_mode_bloc or en_charge:
		return
	
	# Compter les ennemis proches
	var ennemis_proches = 0
	var corps_detectes = charge_detection.get_overlapping_bodies()
	
	for corps in corps_detectes:
		if _est_ennemi(corps) and global_position.distance_to(corps.global_position) < 80:
			ennemis_proches += 1
	
	# Activer défense si 2+ ennemis proches
	if ennemis_proches >= 2:
		activer_mode_bloc()

func _regeneration_defensive(delta):
	# Petit heal en mode défensif
	var vie_comp = $CmpVie
	if vie_comp and vie_comp.has_method("heal"):
		vie_comp.heal(regeneration_bloc * delta)

# =============================================================================
# GESTION DES DÉGÂTS
# =============================================================================

func _on_cmp_vie_death():
	print("Garde-Sanglier: Tombé après ", charges_effectuees, " charges et ", degats_bloques, " dégâts bloqués")
	
	# Effet de mort héroïque
	var tween = create_tween()
	tween.parallel().tween_property(sprite_corps, "modulate:a", 0.0, 2.0)
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 2.0)
	tween.tween_callback(queue_free)

# =============================================================================
# FONCTIONS PUBLIQUES
# =============================================================================

func get_resistance_totale() -> float:
	return resistance_base + bonus_resistance

func est_en_charge() -> bool:
	return en_charge

func est_en_mode_bloc() -> bool:
	return en_mode_bloc

func forcer_charge_vers(cible: Node2D):
	if peut_charger:
		_preparer_charge(cible)

func get_statistiques() -> Dictionary:
	return {
		"charges": charges_effectuees,
		"ennemis_percutes": ennemis_percutes,
		"degats_bloques": degats_bloques,
		"resistance": get_resistance_totale()
	} 