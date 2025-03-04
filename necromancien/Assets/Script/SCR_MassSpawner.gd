extends Node2D

@export var spawnedScene : PackedScene 
@export var spawnNumber : int = 100 #used to instantly spawn a number of mobs
@export var spawnLength : float = 0 # Used for when spawning at a regular interval. Show the interval
@export var spawnArea : Vector2 = Vector2(100,100)

@export_category( " values for spawn ")
@export var destination : Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	for i in spawnNumber :
		
		SpawnMob()
		
	
	if (spawnLength == 0) : return
	$Timer.wait_time = spawnLength
	$Timer.start()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func SpawnMob():
	
	var NewPos = Vector2(randf_range(-spawnArea.x, spawnArea.x), randf_range(-spawnArea.y, spawnArea.y))
	
	var newMob = spawnedScene.instantiate()
	newMob.get_child(0).destination = destination
	newMob.position = NewPos + position
	
	get_parent().add_child.call_deferred(newMob)
	


func _on_timer_timeout():
	
	SpawnMob()
	
