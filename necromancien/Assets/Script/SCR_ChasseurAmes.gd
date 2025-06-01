extends CharacterBody2D
class_name ChasseurAmes

# =============================================================================
# PROPRIÉTÉS DU CHASSEUR D'ÂMES
# =============================================================================

@export_category("Attaques à Distance")
@export var portee_attaque: float = 180.0
@export var vitesse_projectile: float = 200.0
@export var degats_projectile: float = 2.0
@export var cadence_tir: float = 2.5

@export_category("Poursuite")
@export var vitesse_base: float = 110.0
@export var vitesse_poursuite: float = 140.0
@export var distance_poursuite: float = 300.0
@export var precision_tir: float = 0.8

@export_category("Capture d'Âmes")
@export var peut_capturer_ames: bool = true
@export var ames_max: int = 3
@export var bonus_par_ame: float = 0.2
@export var duree_capture: float = 1.0

@export_category("Hybride Bestial")
@export var mode_vol: bool = false
@export var duree_vol: float = 3.0
@export var cooldown_vol: float = 10.0

# =============================================================================
# VARIABLES INTERNES
# =============================================================================

# Système de tir
var cible_actuelle: Node2D = null
var peut_tirer: bool = true
var temps_rechargement: float = 0.0
var projectiles_actifs: Array = []

# Capture d'âmes
var ames_capturees: int = 0
var souls_orbs: Array = []
var en_capture: bool = false

# Poursuite et mouvement
var en_poursuite: bool = false
var derniere_position_cible: Vector2
var temps_poursuite: float = 0.0

# Mode vol
var en_vol: bool = false
var temps_vol_restant: float = 0.0
var altitude_vol: float = 0.0

# Statistiques
var tirs_effectues: int = 0
var ennemis_tues: int = 0
var distance_parcourue: float = 0.0

# Références aux composants
@onready var movement_component = $CMP_movement
@onready var aggression_manager = $CmpAgressionManager
@onready var ranged_detection = $RangedDetection
@onready var attack_timer = $AttackTimer
@onready var reload_timer = $ReloadTimer
@onready var soul_capture_timer = $SoulCaptureTimer
@onready var sprite_corps = $SpriteCorps
@onready var sprite_yeux = $SpriteYeux
@onready var sprite_yeux2 = $SpriteYeux2
@onready var sprite_ailes = $SpriteCorps/SpriteAiles
@onready var sprite_ailes2 = $SpriteCorps/SpriteAiles2
@onready var sprite_arc = $SpriteCorps/SpriteArc
@onready var sprite_aura = $SpriteAura
@onready var projectile_spawn = $ProjectileSpawn
@onready var trajectory_line = $TrajectoryLine
@onready var soul_orbs_container = $SoulOrbs
@onready var effet_tir = $EffetTir

# =============================================================================
# INITIALISATION
# =============================================================================

func _ready():
	# Connecter les signaux
	ranged_detection.body_entered.connect(_on_cible_detectee)
	ranged_detection.body_exited.connect(_on_cible_perdue)
	attack_timer.timeout.connect(_evaluer_tir)
	reload_timer.timeout.connect(_recharger)
	soul_capture_timer.timeout.connect(_finaliser_capture)
	
	# Ajouter aux groupes
	add_to_group("Chasseurs")
	add_to_group("CreaturesDieux")
	add_to_group("RangedAttackers")
	
	# Configuration initiale
	_configurer_apparence_chasseur()
	_ajuster_vitesse_chasseur()
	
	print("Chasseur d'Âmes invoqué - Faction: Créatures des Dieux")

func _configurer_apparence_chasseur():
	# Couleur dorée divine
	sprite_corps.modulate = Color(0.9, 0.8, 0.6, 1.0)
	
	# Yeux bleus lumineux
	sprite_yeux.modulate = Color(0.2, 0.6, 1.0, 1.0)
	sprite_yeux2.modulate = Color(0.2, 0.6, 1.0, 1.0)
	
	# Ailes semi-transparentes
	sprite_ailes.modulate = Color(1.0, 0.9, 0.7, 0.8)
	sprite_ailes2.modulate = Color(1.0, 0.9, 0.7, 0.8)
	
	# Arc mystique
	sprite_arc.modulate = Color(0.7, 0.6, 0.4, 1.0)
	
	# Animation de battement d'ailes
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite_ailes, "rotation", -0.3, 0.8)
	tween.parallel().tween_property(sprite_ailes2, "rotation", 0.3, 0.8)
	tween.tween_property(sprite_ailes, "rotation", -0.7, 0.8)
	tween.parallel().tween_property(sprite_ailes2, "rotation", 0.7, 0.8)

func _ajuster_vitesse_chasseur():
	if movement_component:
		movement_component.speed = vitesse_base

# =============================================================================
# SYSTÈME D'ATTAQUE À DISTANCE
# =============================================================================

func _on_cible_detectee(cible):
	if _est_allie(cible) and not cible_actuelle:
		cible_actuelle = cible
		en_poursuite = true
		temps_poursuite = 0.0
		print("Chasseur d'Âmes: Cible verrouillée - ", cible.name)
		
		# Augmenter la vitesse de poursuite
		if movement_component:
			movement_component.speed = vitesse_poursuite

func _on_cible_perdue(cible):
	if cible == cible_actuelle:
		cible_actuelle = null
		en_poursuite = false
		
		# Restaurer vitesse normale
		if movement_component:
			movement_component.speed = vitesse_base
		
		# Nettoyer la ligne de trajectoire
		trajectory_line.clear_points()

func _est_allie(body) -> bool:
	return body.collision_layer & 2 != 0  # Layer des alliés

func _evaluer_tir():
	if not peut_tirer or not cible_actuelle or not is_instance_valid(cible_actuelle):
		return
	
	var distance = global_position.distance_to(cible_actuelle.global_position)
	if distance <= portee_attaque:
		_tirer_projectile()

func _tirer_projectile():
	if not cible_actuelle or not peut_tirer:
		return
	
	peut_tirer = false
	tirs_effectues += 1
	
	# Calculer direction avec prediction de mouvement
	var direction_tir = _calculer_direction_predictive()
	
	print("Chasseur d'Âmes: Tir vers ", cible_actuelle.name)
	
	# Créer le projectile
	var projectile = _creer_projectile(direction_tir)
	get_parent().add_child(projectile)
	projectiles_actifs.append(projectile)
	
	# Effets visuels
	_effet_tir()
	
	# Démarrer rechargement
	reload_timer.wait_time = cadence_tir
	reload_timer.start()

func _calculer_direction_predictive() -> Vector2:
	if not cible_actuelle:
		return Vector2.RIGHT
	
	var pos_cible = cible_actuelle.global_position
	var velocite_cible = Vector2.ZERO
	
	# Prédire la position future de la cible
	if cible_actuelle.has_method("get_velocity"):
		velocite_cible = cible_actuelle.get_velocity()
	elif cible_actuelle.has_property("velocity"):
		velocite_cible = cible_actuelle.velocity
	
	var temps_vol = global_position.distance_to(pos_cible) / vitesse_projectile
	var pos_predicted = pos_cible + velocite_cible * temps_vol
	
	return (pos_predicted - global_position).normalized()

func _creer_projectile(direction: Vector2) -> Node2D:
	# Créer un projectile simple
	var projectile = preload("res://Entitées/Projectiles/ENT_ProjectileAme.tscn").instantiate()
	
	projectile.global_position = projectile_spawn.global_position
	projectile.setup(direction, vitesse_projectile, degats_projectile, self)
	
	return projectile

func _effet_tir():
	# Montrer la ligne de trajectoire
	if cible_actuelle:
		trajectory_line.clear_points()
		trajectory_line.add_point(Vector2.ZERO)
		trajectory_line.add_point(to_local(cible_actuelle.global_position))
		
		# Faire disparaître la ligne avec un Timer
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 0.3
		timer.one_shot = true
		timer.timeout.connect(func(): trajectory_line.clear_points())
		timer.start()
	
	# Particules de tir
	effet_tir.emitting = true
	
	# Animation de recul de l'arc
	var tween_arc = create_tween()
	tween_arc.tween_property(sprite_arc, "position", Vector2(70, -20), 0.1)
	tween_arc.tween_property(sprite_arc, "position", Vector2(80, -20), 0.2)

func _recharger():
	peut_tirer = true

# =============================================================================
# SYSTÈME DE CAPTURE D'ÂMES
# =============================================================================

func capturer_ame(victime: Node2D):
	if not peut_capturer_ames or ames_capturees >= ames_max:
		return
	
	en_capture = true
	ennemis_tues += 1
	
	print("Chasseur d'Âmes: Capture d'âme de ", victime.name)
	
	# Créer l'orbe d'âme
	var soul_orb = _creer_orbe_ame(victime.global_position)
	soul_orbs_container.add_child(soul_orb)
	souls_orbs.append(soul_orb)
	
	# Démarrer le processus de capture
	soul_capture_timer.start()

func _creer_orbe_ame(position: Vector2) -> Node2D:
	var orb = Node2D.new()
	var sprite = Sprite2D.new()
	
	sprite.texture = preload("res://Assets/SpriteSVG/plain-circle.svg")
	sprite.scale = Vector2(0.02, 0.02)
	sprite.modulate = Color(0.8, 0.9, 1.0, 0.8)
	
	orb.add_child(sprite)
	orb.global_position = position
	
	# Animation de déplacement vers le chasseur
	var tween = create_tween()
	tween.tween_property(orb, "global_position", global_position, duree_capture)
	
	return orb

func _finaliser_capture():
	en_capture = false
	ames_capturees += 1
	
	# Bonus par âme capturée
	_appliquer_bonus_ame()
	
	print("Chasseur d'Âmes: Âme capturée (", ames_capturees, "/", ames_max, ")")

func _appliquer_bonus_ame():
	# Bonus de vitesse et dégâts
	var bonus_total = ames_capturees * bonus_par_ame
	
	if movement_component:
		movement_component.speed = vitesse_base * (1.0 + bonus_total)
	
	degats_projectile = 2.0 * (1.0 + bonus_total)
	
	# Effet visuel renforcé
	sprite_aura.modulate.a = 0.3 + (ames_capturees * 0.2)

# =============================================================================
# MODE VOL
# =============================================================================

func activer_mode_vol():
	if en_vol or not mode_vol:
		return
	
	en_vol = true
	temps_vol_restant = duree_vol
	altitude_vol = 20.0
	
	print("Chasseur d'Âmes: Mode vol activé !")
	
	# Effets visuels de vol
	sprite_corps.position.y = -altitude_vol
	sprite_ailes.modulate.a = 1.0
	sprite_ailes2.modulate.a = 1.0
	
	# Immunité temporaire aux attaques au sol
	collision_mask = 0
	
	# Bonus de vitesse en vol
	if movement_component:
		movement_component.speed = vitesse_poursuite * 1.3

func _desactiver_mode_vol():
	en_vol = false
	altitude_vol = 0.0
	
	# Restaurer position normale
	sprite_corps.position.y = 0
	sprite_ailes.modulate.a = 0.8
	sprite_ailes2.modulate.a = 0.8
	
	# Restaurer collisions
	collision_mask = 2
	
	# Restaurer vitesse
	if movement_component:
		movement_component.speed = vitesse_poursuite if en_poursuite else vitesse_base

# =============================================================================
# BOUCLE PRINCIPALE
# =============================================================================

func _process(delta):
	# Gestion de la poursuite
	if en_poursuite and cible_actuelle:
		_gerer_poursuite(delta)
	
	# Gestion du mode vol
	if en_vol:
		temps_vol_restant -= delta
		if temps_vol_restant <= 0:
			_desactiver_mode_vol()
	
	# Nettoyage des projectiles
	_nettoyer_projectiles()
	
	# Orientation vers la cible
	_orienter_vers_cible()

func _gerer_poursuite(delta):
	temps_poursuite += delta
	
	# Si la cible est trop loin, abandonner
	if cible_actuelle and global_position.distance_to(cible_actuelle.global_position) > distance_poursuite:
		_on_cible_perdue(cible_actuelle)

func _nettoyer_projectiles():
	# Supprimer les projectiles invalides
	projectiles_actifs = projectiles_actifs.filter(func(p): return is_instance_valid(p))

func _orienter_vers_cible():
	if cible_actuelle and is_instance_valid(cible_actuelle):
		look_at(cible_actuelle.global_position)

# =============================================================================
# GESTION DES DÉGÂTS
# =============================================================================

func _on_cmp_vie_death():
	print("Chasseur d'Âmes: Éliminé après ", tirs_effectues, " tirs et ", ames_capturees, " âmes capturées")
	
	# Libérer les âmes capturées
	for orb in souls_orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	
	# Effet de mort divine
	var tween = create_tween()
	tween.parallel().tween_property(sprite_corps, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property(sprite_aura, "scale", Vector2(0.15, 0.15), 1.5)
	tween.parallel().tween_property(sprite_aura, "modulate:a", 0.0, 1.5)
	
	# Détruire après l'animation avec un Timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

# =============================================================================
# FONCTIONS PUBLIQUES
# =============================================================================

func get_cible_actuelle() -> Node2D:
	return cible_actuelle

func get_ames_capturees() -> int:
	return ames_capturees

func est_en_poursuite() -> bool:
	return en_poursuite

func forcer_cible(nouvelle_cible: Node2D):
	cible_actuelle = nouvelle_cible
	en_poursuite = true

func get_statistiques() -> Dictionary:
	return {
		"tirs": tirs_effectues,
		"kills": ennemis_tues,
		"ames": ames_capturees,
		"distance": distance_parcourue
	} 
