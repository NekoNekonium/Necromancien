extends CharacterBody2D
class_name ScoutCerf

# =============================================================================
# PROPRIÉTÉS DU SCOUT-CERF
# =============================================================================

@export_category("Capacités d'Éclaireur")
@export var vitesse_base: float = 150.0
@export var portee_detection: float = 150.0
@export var angle_vision: float = 90.0
@export var precision_detection: float = 0.8

@export_category("Reconnaissance")
@export var duree_scan: float = 1.5
@export var peut_reveiller_allies: bool = true
@export var marque_ennemis: bool = true
@export var temps_marquage: float = 10.0

@export_category("Évasion")
@export var distance_fuite: float = 60.0
@export var boost_fuite: float = 2.0
@export var duree_boost: float = 3.0

@export_category("Communication")
@export var portee_alerte: float = 200.0
@export var peut_coordonner: bool = true

# =============================================================================
# VARIABLES INTERNES
# =============================================================================

var ennemis_detectes: Array = []
var ennemis_marques: Dictionary = {}
var allies_alertes: Array = []
var en_mode_fuite: bool = false
var temps_boost_restant: float = 0.0

# État de reconnaissance
var en_scan: bool = false
var position_scan: Vector2
var cible_scan: Node2D = null
var derniere_alerte: float = 0.0

# Statistiques de détection
var nombre_detections: int = 0
var temps_en_reconnaissance: float = 0.0

# Références aux composants
@onready var movement_component = $CMP_movement
@onready var aggression_manager = $CmpAgressionManager
@onready var detection_area = $DetectionArea
@onready var scan_timer = $ScanTimer
@onready var alert_timer = $AlertTimer
@onready var sprite_corps = $SpriteCorps
@onready var sprite_yeux = $SpriteYeux
@onready var sprite_yeux2 = $SpriteYeux2
@onready var vision_line = $VisionLine
@onready var sprite_cornes = $SpriteCorps/SpriteCornes
@onready var sprite_cornes2 = $SpriteCorps/SpriteCornes2

# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	# Connecter les signaux
	detection_area.body_entered.connect(_on_detection_area_entered)
	detection_area.body_exited.connect(_on_detection_area_exited)
	scan_timer.timeout.connect(_effectuer_scan_periodique)
	alert_timer.timeout.connect(_pulse_alerte)
	
	# Configuration de la zone de détection
	var shape = detection_area.get_child(0).shape as CircleShape2D
	shape.radius = portee_detection
	
	# Ajouter aux groupes
	add_to_group("Scouts")
	add_to_group("Destination")
	
	# Configuration initiale
	_configurer_apparence_cerf()
	_ajuster_vitesse_scout()

func _configurer_apparence_cerf():
	# Couleur brun-fauve du cerf
	sprite_corps.modulate = Color(0.8, 0.6, 0.4, 0.9)
	
	# Yeux bleus perçants d'éclaireur
	sprite_yeux.modulate = Color(0.2, 0.8, 1.0, 1.0)
	sprite_yeux2.modulate = Color(0.2, 0.8, 1.0, 1.0)
	
	# Cornes caractéristiques
	sprite_cornes.modulate = Color(0.6, 0.4, 0.2, 1.0)
	sprite_cornes2.modulate = Color(0.6, 0.4, 0.2, 1.0)
	
	# Animation de mouvement gracieux
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite_corps, "rotation", 0.05, 1.2)
	tween.tween_property(sprite_corps, "rotation", -0.05, 1.2)

func _ajuster_vitesse_scout():
	if movement_component:
		movement_component.speed = vitesse_base

# =============================================================================
# SYSTÈME DE DÉTECTION AVANCÉE
# =============================================================================

func _on_detection_area_entered(body):
	if _est_ennemi(body) and not ennemis_detectes.has(body):
		ennemis_detectes.append(body)
		_detecter_ennemi(body)

func _on_detection_area_exited(body):
	if ennemis_detectes.has(body):
		ennemis_detectes.erase(body)

func _est_ennemi(body) -> bool:
	return body.collision_layer & 4 != 0  # Layer des ennemis

func _detecter_ennemi(ennemi: Node2D):
	if not _peut_voir_ennemi(ennemi):
		return
	
	nombre_detections += 1
	print("Scout-Cerf: Ennemi détecté à ", ennemi.global_position)
	
	# Marquer l'ennemi
	if marque_ennemis:
		_marquer_ennemi(ennemi)
	
	# Alerter les alliés
	_alerter_allies(ennemi)
	
	# Entrer en mode d'évasion si trop proche
	if global_position.distance_to(ennemi.global_position) < distance_fuite:
		_activer_mode_fuite(ennemi)
	
	# Effet visuel de détection
	_effet_detection()

func _peut_voir_ennemi(ennemi: Node2D) -> bool:
	var direction_ennemi = (ennemi.global_position - global_position).normalized()
	var direction_regard = Vector2.RIGHT.rotated(rotation)
	var angle = direction_ennemi.angle_to(direction_regard)
	
	return abs(angle) <= deg_to_rad(angle_vision / 2)

func _marquer_ennemi(ennemi: Node2D):
	ennemis_marques[ennemi] = Time.get_time_dict_from_system()
	
	# Créer un marqueur visuel
	_creer_marqueur_visuel(ennemi)

func _creer_marqueur_visuel(ennemi: Node2D):
	# Créer une ligne de vision vers l'ennemi
	vision_line.clear_points()
	vision_line.add_point(Vector2.ZERO)
	vision_line.add_point(to_local(ennemi.global_position))
	
	# Faire disparaître la ligne après un moment
	var tween = create_tween()
	tween.tween_delay(1.0)
	tween.tween_callback(vision_line.clear_points)

# =============================================================================
# SYSTÈME D'ALERTE ET COORDINATION
# =============================================================================

func _alerter_allies(ennemi: Node2D):
	var allies = get_tree().get_nodes_in_group("Destination")
	
	for allie in allies:
		if allie == self:
			continue
			
		var distance = global_position.distance_to(allie.global_position)
		if distance <= portee_alerte:
			_envoyer_alerte_a_allie(allie, ennemi)

func _envoyer_alerte_a_allie(allie: Node2D, ennemi: Node2D):
	# Si l'allié a une méthode de réception d'alerte
	if allie.has_method("recevoir_alerte_scout"):
		allie.recevoir_alerte_scout(ennemi, self)
	
	# Sinon, alerter via le système global
	if peut_reveiller_allies:
		GlbScrPlayerData.cible = ennemi

func _pulse_alerte():
	# Effet visuel d'alerte
	sprite_yeux.modulate = Color(1.0, 1.0, 0.0, 1.0)
	sprite_yeux2.modulate = Color(1.0, 1.0, 0.0, 1.0)
	
	var tween = create_tween()
	tween.tween_delay(0.1)
	tween.tween_callback(func(): 
		sprite_yeux.modulate = Color(0.2, 0.8, 1.0, 1.0)
		sprite_yeux2.modulate = Color(0.2, 0.8, 1.0, 1.0)
	)

# =============================================================================
# MODE FUITE ET ÉVASION
# =============================================================================

func _activer_mode_fuite(menace: Node2D):
	if en_mode_fuite:
		return
	
	en_mode_fuite = true
	temps_boost_restant = duree_boost
	
	print("Scout-Cerf: Mode fuite activé !")
	
	# Calculer direction de fuite
	var direction_fuite = (global_position - menace.global_position).normalized()
	var position_fuite = global_position + direction_fuite * distance_fuite * 2
	
	# Boost de vitesse
	if movement_component:
		movement_component.speed = vitesse_base * boost_fuite
	
	# Forcer le mouvement vers la position de fuite
	if movement_component and movement_component.navigationComponent:
		movement_component.navigationComponent.target_position = position_fuite
	
	# Effet visuel de panique
	sprite_corps.modulate = Color(1.0, 0.8, 0.6, 1.0)
	
	# Alerter massivement
	alert_timer.start()

func _desactiver_mode_fuite():
	en_mode_fuite = false
	temps_boost_restant = 0.0
	
	# Restaurer vitesse normale
	if movement_component:
		movement_component.speed = vitesse_base
	
	# Restaurer apparence
	sprite_corps.modulate = Color(0.8, 0.6, 0.4, 0.9)
	
	# Arrêter les alertes
	alert_timer.stop()
	
	print("Scout-Cerf: Fin du mode fuite")

# =============================================================================
# SCAN PÉRIODIQUE
# =============================================================================

func _effectuer_scan_periodique():
	# Nettoyer les ennemis marqués expirés
	_nettoyer_marquages_expires()
	
	# Recherche active dans la zone
	_analyser_zone()
	
	# Reporting de statut
	if nombre_detections > 0:
		_rapport_reconnaissance()

func _nettoyer_marquages_expires():
	var temps_actuel = Time.get_time_dict_from_system()
	var a_supprimer = []
	
	for ennemi in ennemis_marques.keys():
		if not is_instance_valid(ennemi):
			a_supprimer.append(ennemi)
			continue
			
		# Vérifier expiration (simplifié)
		if global_position.distance_to(ennemi.global_position) > portee_detection * 1.5:
			a_supprimer.append(ennemi)
	
	for ennemi in a_supprimer:
		ennemis_marques.erase(ennemi)

func _analyser_zone():
	# Compter les ennemis dans la zone
	var ennemis_visibles = 0
	for ennemi in ennemis_detectes:
		if is_instance_valid(ennemi) and _peut_voir_ennemi(ennemi):
			ennemis_visibles += 1
	
	# Ajuster le comportement selon la menace
	if ennemis_visibles >= 3:
		_activer_mode_fuite(ennemis_detectes[0])
	elif ennemis_visibles == 0 and en_mode_fuite:
		_desactiver_mode_fuite()

func _rapport_reconnaissance():
	print("Scout-Cerf: Rapport - ", ennemis_detectes.size(), " ennemis détectés, ", ennemis_marques.size(), " marqués")

# =============================================================================
# BOUCLE PRINCIPALE
# =============================================================================

func _process(delta):
	# Gestion du mode fuite
	if en_mode_fuite:
		temps_boost_restant -= delta
		if temps_boost_restant <= 0:
			_desactiver_mode_fuite()
	
	# Gestion de la patrouille
	_gerer_patrouille(delta)
	
	# Mise à jour des statistiques
	temps_en_reconnaissance += delta
	
	# Orientation vers la cible si en mouvement
	_orienter_vers_mouvement()
	
	# Effet de détection continue
	_effet_detection()

func _orienter_vers_mouvement():
	if movement_component and velocity.length() > 10:
		rotation = velocity.angle()

func _effet_detection():
	# Pulse des yeux selon l'activité
	var intensite = 0.2 + (ennemis_detectes.size() * 0.3)
	sprite_yeux.modulate.a = intensite
	sprite_yeux2.modulate.a = intensite

# =============================================================================
# GESTION DES DÉGÂTS
# =============================================================================

func _on_cmp_vie_death():
	# Alerte finale avant la mort
	if ennemis_detectes.size() > 0:
		_alerter_allies(ennemis_detectes[0])
	
	# Effet de mort gracieuse
	var tween = create_tween()
	tween.parallel().tween_property(sprite_corps, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.2), 1.5)
	tween.tween_callback(queue_free)
	
	print("Scout-Cerf: Éliminé après ", nombre_detections, " détections")

# =============================================================================
# FONCTIONS PUBLIQUES
# =============================================================================

func get_ennemis_detectes() -> Array:
	return ennemis_detectes.duplicate()

func get_nombre_detections() -> int:
	return nombre_detections

func est_en_fuite() -> bool:
	return en_mode_fuite

func forcer_scan_zone():
	_effectuer_scan_periodique()

# Interface pour recevoir des alertes d'autres scouts
func recevoir_alerte_scout(ennemi: Node2D, scout_source: Node2D):
	if not ennemis_detectes.has(ennemi):
		print("Scout-Cerf: Alerte reçue de ", scout_source.name)
		# Orienter vers la menace signalée
		if movement_component and movement_component.navigationComponent:
			movement_component.navigationComponent.target_position = ennemi.global_position

# =============================================================================
# INTERFACE AVEC BASE NEUTRE
# =============================================================================

var faction_allegiance: String = "Neutre"
var base_mere: Node2D = null
var en_patrouille: bool = false
var point_patrouille: Vector2
var temps_patrouille: float = 0.0

func set_faction(nouvelle_faction: String):
	faction_allegiance = nouvelle_faction
	print("Scout-Cerf: Faction changée vers ", nouvelle_faction)

func recevoir_ordre_patrouille(destination: Vector2, base: Node2D):
	en_patrouille = true
	point_patrouille = destination
	base_mere = base
	temps_patrouille = 0.0
	
	# Se diriger vers le point de patrouille
	if movement_component and movement_component.navigationComponent:
		movement_component.navigationComponent.target_position = destination
	
	print("Scout-Cerf: Ordre de patrouille reçu vers ", destination)

func set_hostile_mode(hostile: bool):
	# Ajuster le comportement selon l'hostilité
	if hostile:
		distance_fuite = 40.0  # Plus agressif
		portee_detection = 200.0  # Plus vigilant
	else:
		distance_fuite = 60.0  # Plus prudent
		portee_detection = 150.0  # Normal

func rapport_a_base():
	if base_mere and base_mere.has_method("receive_scout_report"):
		base_mere.receive_scout_report(self, ennemis_detectes)

# =============================================================================
# LOGIQUE DE PATROUILLE
# =============================================================================

func _gerer_patrouille(delta):
	if not en_patrouille:
		return
	
	temps_patrouille += delta
	
	# Vérifier si on a atteint le point de patrouille
	if global_position.distance_to(point_patrouille) < 30.0:
		# Rester sur le point quelques secondes puis retourner
		if temps_patrouille > 10.0:
			_terminer_patrouille()
	
	# Timeout de patrouille
	if temps_patrouille > 60.0:
		_terminer_patrouille()

func _terminer_patrouille():
	en_patrouille = false
	
	# Faire un rapport à la base
	if base_mere:
		rapport_a_base()
	
	# Retourner vers la base
	if base_mere and movement_component and movement_component.navigationComponent:
		movement_component.navigationComponent.target_position = base_mere.global_position
	
	print("Scout-Cerf: Patrouille terminée") 