extends CharacterBody2D
class_name EspritAnimal

# =============================================================================
# PROPRIÉTÉS DE L'ESPRIT ANIMAL
# =============================================================================

@export_category("Comportement de Meute")
@export var rayon_detection_meute: float = 80.0
@export var taille_meute_optimale: int = 3
@export var bonus_meute_vitesse: float = 1.5
@export var bonus_meute_degats: float = 1.3

@export_category("Agressivité")
@export var distance_poursuite: float = 120.0
@export var agressivite_base: float = 1.0
@export var rage_temps: float = 5.0

@export_category("Capacités Animales")
@export var vitesse_base: float = 120.0
@export var detection_ennemi: float = 100.0
@export var instinct_survie: bool = true

# =============================================================================
# VARIABLES INTERNES
# =============================================================================

var membres_meute: Array[EspritAnimal] = []
var chef_meute: EspritAnimal = null
var est_chef: bool = false
var cible_meute: Node2D = null
var en_rage: bool = false
var temps_rage: float = 0.0

# Statistiques de meute
var bonus_actif: bool = false
var multiplicateur_vitesse: float = 1.0
var multiplicateur_degats: float = 1.0
var vitesse_originale: float = 100.0

# Références aux composants
@onready var movement_component = $CMP_movement
@onready var aggression_manager = $CmpAgressionManager
@onready var pack_detection = $PackDetectionArea
@onready var howl_timer = $HowlTimer
@onready var sprite_corps = $SpriteCorps
@onready var sprite_yeux = $SpriteYeux
@onready var sprite_yeux2 = $SpriteYeux2

# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	# Connecter les signaux
	pack_detection.body_entered.connect(_on_esprit_animal_detecte)
	pack_detection.body_exited.connect(_on_esprit_animal_perdu)
	howl_timer.timeout.connect(_hurlement_coordination)
	
	# Configuration de la zone de détection
	var shape = pack_detection.get_child(0).shape as CircleShape2D
	shape.radius = rayon_detection_meute
	
	# Sauvegarder la vitesse originale
	if movement_component:
		vitesse_originale = movement_component.speed
	
	# Ajouter aux groupes
	add_to_group("EspritsAnimaux")
	add_to_group("Destination")
	
	# Configuration initiale
	_configurer_apparence_animale()
	_ajuster_vitesse_base()

func _configurer_apparence_animale():
	# Couleur orangée/fauve spectrale
	sprite_corps.modulate = Color(1.0, 0.6, 0.2, 0.8)
	
	# Yeux rouges brillants
	sprite_yeux.modulate = Color(1.0, 0.0, 0.0, 1.0)
	sprite_yeux2.modulate = Color(1.0, 0.0, 0.0, 1.0)
	
	# Animation de respiration agressive
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite_corps, "scale", Vector2(0.042, 0.042), 0.8)
	tween.tween_property(sprite_corps, "scale", Vector2(0.038, 0.038), 0.8)

func _ajuster_vitesse_base():
	if movement_component:
		movement_component.speed = vitesse_base

# =============================================================================
# SYSTÈME DE MEUTE
# =============================================================================

func _on_esprit_animal_detecte(body):
	if body is EspritAnimal and body != self:
		if not membres_meute.has(body):
			membres_meute.append(body)
			body._rejoindre_meute(self)
			_reorganiser_meute()

func _on_esprit_animal_perdu(body):
	if body is EspritAnimal and membres_meute.has(body):
		membres_meute.erase(body)
		body._quitter_meute(self)
		_reorganiser_meute()

func _rejoindre_meute(leader: EspritAnimal):
	if chef_meute != leader:
		chef_meute = leader
		est_chef = false

func _quitter_meute(leader: EspritAnimal):
	if chef_meute == leader:
		chef_meute = null
		est_chef = false
		_devenir_chef_si_necessaire()

func _reorganiser_meute():
	# Déterminer qui devient le chef (celui avec le plus de membres)
	var taille_ma_meute = membres_meute.size()
	
	if not est_chef and (chef_meute == null or taille_ma_meute >= 2):
		_devenir_chef()
	
	_appliquer_bonus_meute()

func _devenir_chef():
	est_chef = true
	chef_meute = self
	
	# Notifier tous les membres
	for membre in membres_meute:
		if is_instance_valid(membre):
			membre._rejoindre_meute(self)
	
	print("Esprit Animal: Nouveau chef de meute ! (", membres_meute.size(), " membres)")

func _devenir_chef_si_necessaire():
	if membres_meute.size() > 0:
		_devenir_chef()

# =============================================================================
# BONUS DE MEUTE
# =============================================================================

func _appliquer_bonus_meute():
	var taille_totale = membres_meute.size() + 1  # +1 pour soi-même
	
	if taille_totale >= 2:
		bonus_actif = true
		multiplicateur_vitesse = 1.0 + (taille_totale * 0.2)
		multiplicateur_degats = 1.0 + (taille_totale * 0.15)
		
		# Effet visuel de meute
		sprite_corps.modulate = Color(1.2, 0.7, 0.1, 0.9)
		sprite_yeux.modulate = Color(1.5, 0.2, 0.0, 1.0)
		sprite_yeux2.modulate = Color(1.5, 0.2, 0.0, 1.0)
	else:
		bonus_actif = false
		multiplicateur_vitesse = 1.0
		multiplicateur_degats = 1.0
		
		# Apparence normale
		sprite_corps.modulate = Color(1.0, 0.6, 0.2, 0.8)
		sprite_yeux.modulate = Color(1.0, 0.0, 0.0, 1.0)
		sprite_yeux2.modulate = Color(1.0, 0.0, 0.0, 1.0)
	
	# Appliquer les bonus
	if movement_component:
		movement_component.speed = vitesse_base * multiplicateur_vitesse

# =============================================================================
# COORDINATION D'ATTAQUE
# =============================================================================

func _hurlement_coordination():
	if est_chef and membres_meute.size() > 0:
		_coordonner_attaque_meute()

func _coordonner_attaque_meute():
	# Trouver la meilleure cible
	var meilleure_cible = _trouver_cible_prioritaire()
	
	if meilleure_cible:
		cible_meute = meilleure_cible
		
		# Commander la meute
		for membre in membres_meute:
			if is_instance_valid(membre):
				membre._recevoir_ordre_attaque(meilleure_cible)
		
		# Attaquer soi-même
		_recevoir_ordre_attaque(meilleure_cible)
		
		print("Chef de meute: Attaque coordonnée sur cible !")

func _recevoir_ordre_attaque(cible: Node2D):
	if cible and aggression_manager:
		GlbScrPlayerData.cible = cible
		
		# Entrer en rage
		_entrer_en_rage()

func _trouver_cible_prioritaire() -> Node2D:
	var ennemis = get_tree().get_nodes_in_group("EnnemyBase")
	var cible_proche = null
	var distance_min = detection_ennemi
	
	for ennemi in ennemis:
		var distance = global_position.distance_to(ennemi.global_position)
		if distance < distance_min:
			distance_min = distance
			cible_proche = ennemi
	
	return cible_proche

# =============================================================================
# ÉTAT DE RAGE
# =============================================================================

func _entrer_en_rage():
	if en_rage:
		return
	
	en_rage = true
	temps_rage = rage_temps
	
	# Effets visuels de rage
	sprite_corps.modulate = Color(1.5, 0.3, 0.0, 1.0)
	
	# Bonus de rage
	if movement_component:
		movement_component.speed = vitesse_base * multiplicateur_vitesse * 1.5

func _sortir_rage():
	en_rage = false
	temps_rage = 0.0
	
	# Restaurer l'apparence
	_appliquer_bonus_meute()

func _process(delta):
	if en_rage:
		temps_rage -= delta
		if temps_rage <= 0:
			_sortir_rage()
	
	# Comportement agressif continu
	_gerer_agressivite()
	
	# Mise à jour de la meute
	if est_chef:
		_gerer_leadership()

# =============================================================================
# COMPORTEMENT AGRESSIF
# =============================================================================

func _gerer_agressivite():
	# Recherche active d'ennemis
	var ennemis_proches = _detecter_ennemis_proches()
	
	if ennemis_proches.size() > 0 and not en_rage:
		var cible_la_plus_proche = ennemis_proches[0]
		
		# Attaquer automatiquement
		if movement_component and aggression_manager:
			GlbScrPlayerData.cible = cible_la_plus_proche
			_entrer_en_rage()

func _detecter_ennemis_proches() -> Array:
	var ennemis = []
	var tous_ennemis = get_tree().get_nodes_in_group("EnnemyBase")
	
	for ennemi in tous_ennemis:
		if global_position.distance_to(ennemi.global_position) <= distance_poursuite:
			ennemis.append(ennemi)
	
	# Trier par distance
	ennemis.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	
	return ennemis

func _gerer_leadership():
	# Vérifier que les membres sont toujours valides
	membres_meute = membres_meute.filter(func(membre): return is_instance_valid(membre))
	
	# Partager la cible avec la meute
	if cible_meute and is_instance_valid(cible_meute):
		for membre in membres_meute:
			if is_instance_valid(membre) and membre.cible_meute != cible_meute:
				membre._recevoir_ordre_attaque(cible_meute)

# =============================================================================
# GESTION DES DÉGÂTS ET MORT
# =============================================================================

func _on_cmp_vie_death():
	# Notifier la meute de la mort
	if est_chef and membres_meute.size() > 0:
		membres_meute[0]._devenir_chef()
	
	for membre in membres_meute:
		if is_instance_valid(membre):
			membre._quitter_meute(self)
	
	# Effet de mort animale
	var tween = create_tween()
	tween.parallel().tween_property(sprite_corps, "modulate", Color(0.5, 0.2, 0.0, 0.0), 1.0)
	tween.parallel().tween_property(self, "scale", Vector2(1.2, 0.2), 1.0)
	tween.tween_callback(queue_free)

# =============================================================================
# FONCTIONS PUBLIQUES
# =============================================================================

func get_taille_meute() -> int:
	return membres_meute.size() + 1

func est_en_meute() -> bool:
	return membres_meute.size() > 0 or chef_meute != null

func get_bonus_degats() -> float:
	return multiplicateur_degats if bonus_actif else 1.0 
