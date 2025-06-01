extends CharacterBody2D
class_name Purificateur

# =============================================================================
# PROPRIÉTÉS DU PURIFICATEUR
# =============================================================================

@export_category("Capacités de Soin")
@export var portee_soin: float = 120.0
@export var puissance_soin: float = 2.0
@export var cooldown_soin: float = 3.0
@export var soin_max_par_cible: float = 6.0

@export_category("Protection Divine")
@export var bouclier_temporaire: float = 3.0
@export var duree_bouclier: float = 5.0
@export var cooldown_bouclier: float = 8.0
@export var resistance_degats: float = 0.3

@export_category("Déplacement Tank")
@export var vitesse_base: float = 80.0
@export var vitesse_soin: float = 50.0
@export var distance_garde: float = 150.0
@export var mode_defensif: bool = true

@export_category("Miracles")
@export var peut_ressusciter: bool = true
@export var cooldown_resurrection: float = 15.0
@export var cout_resurrection: float = 4.0
@export var portee_resurrection: float = 80.0

@export_category("Benedictions")
@export var aura_benediction: bool = true
@export var bonus_vitesse_allies: float = 0.15
@export var bonus_regeneration: float = 0.5
@export var portee_benediction: float = 100.0

# =============================================================================
# VARIABLES INTERNES
# =============================================================================

# Système de soin
var allies_dans_portee: Array = []
var cible_soin_prioritaire: Node2D = null
var peut_soigner: bool = true
var soins_effectues: int = 0

# Protection et boucliers
var allies_proteges: Dictionary = {}
var boucliers_actifs: Dictionary = {}
var peut_bouclier: bool = true

# Résurrection
var peut_faire_resurrection: bool = true
var cadavres_detectes: Array = []
var resurrections_effectuees: int = 0

# Bénédictions
var allies_benedictions: Dictionary = {}
var benedictions_actives: int = 0

# Statistiques
var total_hp_soigne: float = 0.0
var allies_sauves: int = 0
var degats_bloques: float = 0.0

# État interne
var en_priere: bool = false
var en_mode_defensif: bool = true
var position_garde: Vector2
var derniere_priere: float = 0.0

# Références aux composants
@onready var movement_component = $CMP_movement
@onready var aggression_manager = $CmpAgressionManager
@onready var heal_aura = $HealAura
@onready var heal_timer = $HealTimer
@onready var shield_timer = $ShieldTimer
@onready var prayer_timer = $PrayerTimer
@onready var resurrection_timer = $ResurrectionTimer
@onready var sprite_corps = $SpriteCorps
@onready var sprite_armure = $SpriteCorps/SpriteArmure
@onready var sprite_bouclier = $SpriteCorps/SpriteBouclier
@onready var sprite_marteau = $SpriteCorps/SpriteMarteau
@onready var sprite_casque = $SpriteCorps/SpriteCasque
@onready var sprite_aile_droite = $SpriteCorps/SpriteAileDroite
@onready var sprite_aile_gauche = $SpriteCorps/SpriteAileGauche
@onready var sprite_halo = $SpriteCorps/SpriteHalo
@onready var aura_divine = $AuraDivine
@onready var sprite_yeux = $SpriteYeux
@onready var sprite_yeux2 = $SpriteYeux2
@onready var effet_soin = $EffetSoin
@onready var effet_bouclier = $EffetBouclier
@onready var effet_priere = $EffetPriere

# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	# Connecter les signaux
	heal_aura.body_entered.connect(_on_allie_dans_portee)
	heal_aura.body_exited.connect(_on_allie_hors_portee)
	heal_timer.timeout.connect(_effectuer_soin)
	shield_timer.timeout.connect(_activer_bouclier_groupe)
	prayer_timer.timeout.connect(_effectuer_priere)
	resurrection_timer.timeout.connect(_activer_resurrection)
	
	# Ajouter aux groupes
	add_to_group("Purificateurs")
	add_to_group("CreaturesDieux")
	add_to_group("Healers")
	add_to_group("Tanks")
	
	# Configuration initiale
	_configurer_apparence_purificateur()
	_ajuster_vitesse_purificateur()
	position_garde = global_position
	
	print("Purificateur consacré - Faction: Créatures des Dieux")

func _configurer_apparence_purificateur():
	# Couleur divine dorée
	sprite_corps.modulate = Color(0.95, 0.9, 0.7, 1.0)
	
	# Armure sainte
	sprite_armure.modulate = Color(0.8, 0.8, 0.9, 0.9)
	sprite_casque.modulate = Color(0.8, 0.75, 0.6, 1.0)
	
	# Équipement divin
	sprite_bouclier.modulate = Color(0.9, 0.85, 0.6, 1.0)
	sprite_marteau.modulate = Color(0.7, 0.6, 0.5, 1.0)
	
	# Yeux bleus lumineux
	sprite_yeux.modulate = Color(0.2, 0.8, 1.0, 1.0)
	sprite_yeux2.modulate = Color(0.2, 0.8, 1.0, 1.0)
	
	# Ailes et halo divins
	sprite_aile_droite.modulate = Color(1.0, 1.0, 0.9, 0.7)
	sprite_aile_gauche.modulate = Color(1.0, 1.0, 0.9, 0.7)
	sprite_halo.modulate = Color(1.0, 0.95, 0.7, 0.6)
	
	# Animation du halo
	var tween_halo = create_tween()
	tween_halo.set_loops()
	tween_halo.tween_property(sprite_halo, "modulate:a", 0.3, 2.0)
	tween_halo.tween_property(sprite_halo, "modulate:a", 0.8, 2.0)

func _ajuster_vitesse_purificateur():
	if movement_component:
		movement_component.speed = vitesse_base

# =============================================================================
# SYSTÈME DE SOIN
# =============================================================================

func _on_allie_dans_portee(allie):
	if _est_allie(allie) and allie != self:
		allies_dans_portee.append(allie)
		print("Purificateur: Allié détecté - ", allie.name)

func _on_allie_hors_portee(allie):
	if allie in allies_dans_portee:
		allies_dans_portee.erase(allie)

func _est_allie(body) -> bool:
	return body.collision_layer & 4 != 0  # Layer des alliés

func _effectuer_soin():
	if not peut_soigner or allies_dans_portee.is_empty():
		return
	
	# Trouver l'allié le plus blessé
	var cible_prioritaire = _trouver_allie_plus_blesse()
	if not cible_prioritaire:
		return
	
	# Soigner la cible
	_soigner_allie(cible_prioritaire)

func _trouver_allie_plus_blesse() -> Node2D:
	var cible_prioritaire: Node2D = null
	var pourcentage_vie_min = 1.0
	
	for allie in allies_dans_portee:
		if not is_instance_valid(allie):
			continue
			
		var comp_vie = allie.get_node_or_null("CmpVie")
		if not comp_vie:
			continue
		
		var pourcentage_vie = float(comp_vie.life) / float(comp_vie.Max_life)
		if pourcentage_vie < pourcentage_vie_min and pourcentage_vie < 0.8:
			pourcentage_vie_min = pourcentage_vie
			cible_prioritaire = allie
	
	return cible_prioritaire

func _soigner_allie(cible: Node2D):
	var comp_vie = cible.get_node_or_null("CmpVie")
	if not comp_vie or not comp_vie.has_method("changeLife"):
		return
	
	var soin_effectif = min(puissance_soin, comp_vie.Max_life - comp_vie.life)
	if soin_effectif <= 0:
		return
	
	# Utiliser changeLife avec un modificateur positif (false = pas une attaque)
	comp_vie.changeLife(int(soin_effectif), false)
	soins_effectues += 1
	total_hp_soigne += soin_effectif
	
	print("Purificateur: +", soin_effectif, " HP à ", cible.name)
	
	# Effet visuel de soin
	_effet_soin_cible(cible)
	effet_soin.emitting = true

func _effet_soin_cible(cible: Node2D):
	# Créer des particules de soin sur la cible
	var heal_particles = CPUParticles2D.new()
	cible.add_child(heal_particles)
	
	heal_particles.emitting = true
	heal_particles.amount = 8
	heal_particles.lifetime = 1.5
	heal_particles.direction = Vector2(0, -1)
	heal_particles.spread = 45.0
	heal_particles.initial_velocity_min = 20.0
	heal_particles.initial_velocity_max = 40.0
	heal_particles.color = Color(0.2, 1.0, 0.4, 0.8)
	
	# Supprimer après l'effet
	var timer = Timer.new()
	cible.add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): heal_particles.queue_free())
	timer.start()

# =============================================================================
# SYSTÈME DE PROTECTION
# =============================================================================

func _activer_bouclier_groupe():
	if not peut_bouclier or allies_dans_portee.is_empty():
		return
	
	peut_bouclier = false
	
	print("Purificateur: Bouclier divin activé !")
	
	# Appliquer bouclier à tous les alliés proches
	for allie in allies_dans_portee:
		if is_instance_valid(allie):
			_appliquer_bouclier(allie)
	
	# Effet visuel
	effet_bouclier.emitting = true
	
	# Cooldown
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = cooldown_bouclier
	timer.one_shot = true
	timer.timeout.connect(func(): peut_bouclier = true)
	timer.start()

func _appliquer_bouclier(cible: Node2D):
	var comp_vie = cible.get_node_or_null("CmpVie")
	if not comp_vie:
		return
	
	# Ajouter bouclier temporaire
	boucliers_actifs[cible] = bouclier_temporaire
	allies_proteges[cible] = true
	
	# Effet visuel sur la cible
	var shield_sprite = Sprite2D.new()
	shield_sprite.texture = preload("res://Assets/SpriteSVG/plain-circle.svg")
	shield_sprite.scale = Vector2(0.08, 0.08)
	shield_sprite.modulate = Color(0.8, 0.8, 1.0, 0.5)
	cible.add_child(shield_sprite)
	
	# Animation du bouclier
	var tween = create_tween()
	tween.tween_property(shield_sprite, "modulate:a", 0.0, duree_bouclier)
	tween.tween_callback(func(): _retirer_bouclier(cible, shield_sprite))

func _retirer_bouclier(cible: Node2D, shield_sprite: Sprite2D):
	if cible in boucliers_actifs:
		boucliers_actifs.erase(cible)
	if cible in allies_proteges:
		allies_proteges.erase(cible)
	
	if is_instance_valid(shield_sprite):
		shield_sprite.queue_free()

# =============================================================================
# SYSTÈME DE RÉSURRECTION
# =============================================================================

func _activer_resurrection():
	if not peut_faire_resurrection:
		return
	
	# Chercher des cadavres d'alliés
	var cadavres = get_tree().get_nodes_in_group("DeadAllies")
	if cadavres.is_empty():
		return
	
	# Trouver le cadavre le plus proche
	var cadavre_proche = null
	var distance_min = portee_resurrection
	
	for cadavre in cadavres:
		var distance = global_position.distance_to(cadavre.global_position)
		if distance < distance_min:
			distance_min = distance
			cadavre_proche = cadavre
	
	if cadavre_proche:
		_ressusciter_allie(cadavre_proche)

func _ressusciter_allie(cadavre: Node2D):
	peut_faire_resurrection = false
	resurrections_effectuees += 1
	
	print("Purificateur: Résurrection divine !")
	
	# Effet de résurrection
	effet_priere.emitting = true
	
	# Restaurer l'allié (logique à implémenter selon le système de mort)
	if cadavre.has_method("resurrect"):
		cadavre.resurrect(soin_max_par_cible / 2)
	
	# Cooldown résurrection
	resurrection_timer.start()
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = cooldown_resurrection
	timer.one_shot = true
	timer.timeout.connect(func(): peut_faire_resurrection = true)
	timer.start()

# =============================================================================
# SYSTÈME DE BÉNÉDICTIONS
# =============================================================================

func _effectuer_priere():
	en_priere = true
	effet_priere.emitting = true
	
	# Appliquer bénédictions aux alliés
	for allie in allies_dans_portee:
		if is_instance_valid(allie):
			_appliquer_benediction(allie)
	
	# Animation de prière
	var tween = create_tween()
	tween.tween_property(sprite_halo, "scale", Vector2(2.0, 0.4), 0.8)
	tween.tween_property(sprite_halo, "scale", Vector2(1.5, 0.3), 0.7)
	
	# Fin de prière
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): en_priere = false)
	timer.start()

func _appliquer_benediction(cible: Node2D):
	if cible in allies_benedictions:
		return
	
	allies_benedictions[cible] = true
	benedictions_actives += 1
	
	# Bonus de vitesse
	var comp_movement = cible.get_node_or_null("CMP_movement")
	if comp_movement:
		comp_movement.speed *= (1.0 + bonus_vitesse_allies)
	
	print("Purificateur: Bénédiction accordée à ", cible.name)

# =============================================================================
# BOUCLE PRINCIPALE
# =============================================================================

func _process(delta):
	# Gestion mode défensif
	if en_mode_defensif:
		_gerer_position_garde(delta)
	
	# Mise à jour aura divine
	_animer_aura_divine(delta)
	
	# Nettoyage des références invalides
	_nettoyer_references()

func _gerer_position_garde(delta):
	# Rester près des alliés blessés
	if not allies_dans_portee.is_empty():
		var cible_garde = _trouver_allie_plus_blesse()
		if cible_garde:
			var distance = global_position.distance_to(cible_garde.global_position)
			if distance > distance_garde:
				# Se rapprocher de l'allié blessé
				if movement_component:
					movement_component.speed = vitesse_soin

func _animer_aura_divine(delta):
	# Pulsation de l'aura selon l'activité
	var intensite_base = 0.2
	if en_priere:
		intensite_base = 0.4
	elif not allies_dans_portee.is_empty():
		intensite_base = 0.3
	
	var temps_actuel = Time.get_ticks_msec() / 1000.0
	var pulse = sin(temps_actuel * 3.0) * 0.1 + intensite_base
	aura_divine.modulate.a = pulse

func _nettoyer_references():
	# Nettoyer les alliés invalides
	allies_dans_portee = allies_dans_portee.filter(func(a): return is_instance_valid(a))
	
	# Nettoyer les boucliers expirés
	for cible in boucliers_actifs.keys():
		if not is_instance_valid(cible):
			boucliers_actifs.erase(cible)

# =============================================================================
# GESTION DES DÉGÂTS
# =============================================================================

func _on_cmp_vie_death():
	print("Purificateur: Retour au divin après ", soins_effectues, " soins et ", resurrections_effectuees, " résurrections")
	
	# Retirer toutes les bénédictions
	for allie in allies_benedictions.keys():
		if is_instance_valid(allie):
			var comp_movement = allie.get_node_or_null("CMP_movement")
			if comp_movement:
				comp_movement.speed /= (1.0 + bonus_vitesse_allies)
	
	# Effet de mort divine
	var tween = create_tween()
	tween.parallel().tween_property(sprite_corps, "modulate:a", 0.0, 2.0)
	tween.parallel().tween_property(aura_divine, "scale", Vector2(0.3, 0.3), 2.0)
	tween.parallel().tween_property(sprite_halo, "scale", Vector2(3.0, 0.8), 2.0)
	tween.parallel().tween_property(sprite_halo, "modulate:a", 0.0, 2.0)
	
	# Dernière bénédiction (explosion de soin)
	for allie in allies_dans_portee:
		if is_instance_valid(allie):
			_soigner_allie(allie)
	
	# Destruction après l'animation
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

# =============================================================================
# FONCTIONS PUBLIQUES
# =============================================================================

func get_allies_soignes() -> int:
	return soins_effectues

func get_total_hp_soigne() -> float:
	return total_hp_soigne

func get_resurrections() -> int:
	return resurrections_effectuees

func forcer_soin_urgence(cible: Node2D):
	if cible in allies_dans_portee:
		_soigner_allie(cible)

func get_statistiques() -> Dictionary:
	return {
		"soins": soins_effectues,
		"hp_soigne": total_hp_soigne,
		"resurrections": resurrections_effectuees,
		"allies_sauves": allies_sauves,
		"benedictions": benedictions_actives
	} 
