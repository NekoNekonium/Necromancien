extends RigidBody2D
class_name ProjectileAme

# =============================================================================
# PROPRIÉTÉS DU PROJECTILE
# =============================================================================

var direction: Vector2
var vitesse: float
var degats: float
var tireur: Node2D
var distance_parcourue: float = 0.0
var distance_max: float = 400.0

@onready var sprite_projectile = $SpriteProjectile
@onready var sprite_aura = $SpriteAura
@onready var trail_particles = $TrailParticles
@onready var impact_timer = $ImpactTimer
@onready var hit_area = $HitArea

# =============================================================================
# INITIALISATION
# =============================================================================

func setup(direction_tir: Vector2, vitesse_tir: float, degats_tir: float, tireur_ref: Node2D):
	direction = direction_tir.normalized()
	vitesse = vitesse_tir
	degats = degats_tir
	tireur = tireur_ref
	
	# Orientation du projectile
	rotation = direction.angle()
	
	# Vélocité initiale
	linear_velocity = direction * vitesse
	
	print("Projectile d'Âme créé - Dégâts: ", degats)

func _ready():
	# Connecter les signaux
	hit_area.body_entered.connect(_on_hit)
	impact_timer.timeout.connect(_on_timeout)
	
	# Animation de rotation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite_projectile, "rotation", 2 * PI, 1.0)

# =============================================================================
# MOUVEMENT ET DÉTECTION
# =============================================================================

func _physics_process(delta):
	# Calculer distance parcourue
	distance_parcourue += linear_velocity.length() * delta
	
	# Autodestruction si trop loin
	if distance_parcourue >= distance_max:
		_exploser()
	
	# Effet de pulsation
	var temps_actuel = Time.get_ticks_msec() / 1000.0
	var pulse = sin(temps_actuel * 8.0) * 0.1 + 1.0
	sprite_aura.scale = Vector2(0.04, 0.04) * pulse

func _on_hit(body):
	if body == tireur:
		return  # Éviter de toucher le tireur
	
	# Infliger des dégâts si l'entité a un composant de vie
	var comp_vie = body.get_node_or_null("CmpVie")
	if comp_vie and comp_vie.has_method("changeLife"):
		# Infliger des dégâts (valeur négative, true = attaque)
		comp_vie.changeLife(-int(degats), true)
		print("Projectile d'Âme: ", degats, " dégâts infligés à ", body.name)
		
		# Notifier le tireur de l'impact réussi
		if tireur and tireur.has_method("capturer_ame"):
			# Si la cible meurt, capturer son âme
			if comp_vie.life <= degats:
				tireur.capturer_ame(body)
	
	# Exploser à l'impact
	_exploser()

func _on_timeout():
	print("Projectile d'Âme: Timeout - Autodestruction")
	_exploser()

# =============================================================================
# EFFETS D'EXPLOSION
# =============================================================================

func _exploser():
	# Désactiver les collisions
	set_collision_layer(0)
	set_collision_mask(0)
	linear_velocity = Vector2.ZERO
	
	# Arrêter les particules de trail
	trail_particles.emitting = false
	
	# Effet d'explosion
	_effet_explosion()
	
	# Détruire après l'animation avec un Timer
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

func _effet_explosion():
	# Particules d'explosion
	var explosion_particles = CPUParticles2D.new()
	add_child(explosion_particles)
	
	explosion_particles.emitting = true
	explosion_particles.amount = 20
	explosion_particles.lifetime = 0.8
	explosion_particles.speed_scale = 2.0
	explosion_particles.direction = Vector2(0, 0)
	explosion_particles.spread = 360.0
	explosion_particles.initial_velocity_min = 50.0
	explosion_particles.initial_velocity_max = 100.0
	explosion_particles.scale_amount_min = 0.2
	explosion_particles.scale_amount_max = 0.5
	explosion_particles.color = Color(0.2, 0.6, 1.0, 0.8)
	
	# Animation de disparition
	var tween = create_tween()
	tween.parallel().tween_property(sprite_projectile, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(sprite_aura, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(sprite_aura, "scale", Vector2(0.1, 0.1), 0.5)
	
	print("Projectile d'Âme: Explosion d'énergie divine") 