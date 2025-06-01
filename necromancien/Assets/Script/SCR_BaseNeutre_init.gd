extends Node2D
class_name BaseNeutre

# =============================================================================
# PROPRIÉTÉS DE LA BASE NEUTRE
# =============================================================================

@export_category("Gestion de la Base")
@export var faction_name: String = "Serviteurs des Ogres"
@export var defense_level: int = 2
@export var patrol_range: float = 300.0
@export var max_scouts: int = 3

@export_category("Production")
@export var auto_production: bool = true
@export var production_rate: float = 15.0
@export var resource_generation: float = 2.0

@export_category("Comportement")
@export var is_hostile_to_player: bool = false
@export var ally_with_player: bool = false
@export var territorial_behavior: bool = true

# =============================================================================
# VARIABLES INTERNES
# =============================================================================

var scouts_deployed: Array = []
var patrol_points: Array = []
var current_resources: float = 5.0
var base_level: int = 1

# État de la base
var under_attack: bool = false
var last_patrol_time: float = 0.0
var alert_level: int = 0  # 0=Calme, 1=Vigilant, 2=Alerte

# Statistiques
var scouts_produced: int = 0
var intruders_detected: int = 0
var alliances_formed: int = 0

# Références aux composants
@onready var spawner = $SpawnerScoutCerf
@onready var material_harvester = $CMP_CreatureMaterial
@onready var patrol_timer = $TimerPatrouille
@onready var influence_area = $ZoneInfluence
@onready var life_component = $CMP_vie
@onready var particles = $ParticulesFumee

# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	# Connecter les signaux
	patrol_timer.timeout.connect(_organiser_patrouille)
	if spawner:
		spawner.automation = auto_production
		spawner.automationTime = production_rate
	
	# Initialiser les points de patrouille
	_generer_points_patrouille()
	
	# Configuration de base
	add_to_group("BasesNeutres")
	add_to_group("Territorial")
	
	# Démarrer la production
	if auto_production:
		_demarrer_production()
	
	print("Base Neutre initialisée - Faction: ", faction_name)

func _generer_points_patrouille():
	# Créer des points de patrouille autour de la base
	var angle_step = 2 * PI / 6  # 6 points de patrouille
	for i in range(6):
		var angle = i * angle_step
		var point = global_position + Vector2(cos(angle), sin(angle)) * patrol_range
		patrol_points.append(point)

func _demarrer_production():
	# Configuration du spawner
	if spawner:
		spawner.creatureCost = 3  # Coût réduit pour la base neutre
		spawner.automation = true
		spawner.automationTime = production_rate

# =============================================================================
# GESTION DES RESSOURCES
# =============================================================================

func _process(delta):
	# Génération passive de ressources
	current_resources += resource_generation * delta
	
	# Gestion de l'état de la base
	_update_base_status(delta)
	
	# Surveillance des scouts
	_monitor_scouts()
	
	# Gestion des effets visuels
	_update_visual_effects()

func _update_base_status(delta):
	# Mise à jour du niveau d'alerte
	if under_attack:
		alert_level = 2
		particles.amount = 25  # Plus de fumée en cas d'attaque
	elif intruders_detected > 0:
		alert_level = 1
		particles.amount = 20
	else:
		alert_level = 0
		particles.amount = 15

func _monitor_scouts():
	# Nettoyer les scouts détruits
	scouts_deployed = scouts_deployed.filter(func(scout): return is_instance_valid(scout))
	
	# Compter les scouts actifs
	var active_scouts = scouts_deployed.size()
	
	# Ajuster la production selon les besoins
	if active_scouts < max_scouts and auto_production:
		if spawner and not spawner.automation:
			spawner.automation = true

# =============================================================================
# SYSTÈME DE PATROUILLE
# =============================================================================

func _organiser_patrouille():
	if scouts_deployed.size() == 0:
		print("Base Neutre: Aucun scout disponible pour patrouille")
		return
	
	# Sélectionner un scout pour la patrouille
	var scout = scouts_deployed[randi() % scouts_deployed.size()]
	if not is_instance_valid(scout):
		return
	
	# Assigner un point de patrouille
	var patrol_point = patrol_points[randi() % patrol_points.size()]
	_envoyer_en_patrouille(scout, patrol_point)
	
	last_patrol_time = Time.get_time_dict_from_system()["unix"]
	print("Base Neutre: Patrouille organisée vers ", patrol_point)

func _envoyer_en_patrouille(scout: Node2D, destination: Vector2):
	if scout.has_method("recevoir_ordre_patrouille"):
		scout.recevoir_ordre_patrouille(destination, self)
	elif scout.has_method("set_target_position"):
		scout.set_target_position(destination)
	else:
		# Utiliser le système de navigation standard
		if scout.has_node("CMP_movement") and scout.has_node("CMP_Navigation"):
			var nav = scout.get_node("CMP_Navigation")
			nav.target_position = destination

# =============================================================================
# GESTION DES RELATIONS
# =============================================================================

func _on_scout_produced(scout: Node2D):
	scouts_deployed.append(scout)
	scouts_produced += 1
	
	# Configurer le scout pour la faction neutre
	if scout.has_method("set_faction"):
		scout.set_faction("Serviteurs")
	
	# Ajouter au groupe des scouts neutres
	scout.add_to_group("ScoutsNeutres")
	
	print("Base Neutre: Scout-Cerf déployé (Total: ", scouts_deployed.size(), ")")

func detect_intruder(intruder: Node2D):
	intruders_detected += 1
	
	# Alerter tous les scouts
	for scout in scouts_deployed:
		if is_instance_valid(scout) and scout.has_method("recevoir_alerte_scout"):
			scout.recevoir_alerte_scout(intruder, self)
	
	# Augmenter le niveau d'alerte
	if not under_attack:
		under_attack = true
		_activate_defense_mode()
	
	print("Base Neutre: Intrus détecté - ", intruder.name)

func _activate_defense_mode():
	# Accélérer la production
	if spawner:
		spawner.automationTime = production_rate * 0.6
	
	# Intensifier les patrouilles
	patrol_timer.wait_time = 10.0
	
	# Effets visuels de défense
	particles.emitting = true
	particles.amount = 30

func _deactivate_defense_mode():
	under_attack = false
	
	# Restaurer le rythme normal
	if spawner:
		spawner.automationTime = production_rate
	
	patrol_timer.wait_time = 20.0
	particles.amount = 15

# =============================================================================
# DIPLOMATIE ET ALLIANCES
# =============================================================================

func propose_alliance(other_faction: Node2D) -> bool:
	if ally_with_player and other_faction.is_in_group("PlayerBase"):
		alliances_formed += 1
		print("Base Neutre: Alliance formée avec ", other_faction.name)
		return true
	return false

func set_hostility(hostile: bool):
	is_hostile_to_player = hostile
	
	# Changer le comportement des scouts
	for scout in scouts_deployed:
		if is_instance_valid(scout) and scout.has_method("set_hostile_mode"):
			scout.set_hostile_mode(hostile)

func _update_visual_effects():
	# Couleur du drapeau selon l'alliance
	var flag = $DrapeauNeutre
	if ally_with_player:
		flag.default_color = Color(0.2, 0.8, 0.3, 1)  # Vert ami
	elif is_hostile_to_player:
		flag.default_color = Color(0.8, 0.2, 0.2, 1)  # Rouge ennemi
	else:
		flag.default_color = Color(0.8, 0.7, 0.5, 1)  # Neutre

# =============================================================================
# ÉVÉNEMENTS EXTERNES
# =============================================================================

func receive_scout_report(scout: Node2D, enemies_detected: Array):
	if enemies_detected.size() > 0:
		intruders_detected += enemies_detected.size()
		
		# Envoyer des renforts si nécessaire
		if enemies_detected.size() >= 2:
			_send_reinforcements(scout.global_position)

func _send_reinforcements(position: Vector2):
	var available_scouts = scouts_deployed.filter(
		func(scout): return is_instance_valid(scout) and not scout.est_en_fuite()
	)
	
	# Envoyer jusqu'à 2 scouts en renfort
	var reinforcements = min(2, available_scouts.size())
	for i in range(reinforcements):
		_envoyer_en_patrouille(available_scouts[i], position)

# =============================================================================
# INTERFACE PUBLIQUE
# =============================================================================

func get_faction_name() -> String:
	return faction_name

func get_scout_count() -> int:
	return scouts_deployed.size()

func get_alert_level() -> int:
	return alert_level

func is_ally_with_player() -> bool:
	return ally_with_player

func set_ally_with_player(ally: bool):
	ally_with_player = ally
	is_hostile_to_player = not ally

# Méthode appelée par le spawner quand une créature est produite
func on_creature_spawned(creature: Node2D):
	_on_scout_produced(creature) 