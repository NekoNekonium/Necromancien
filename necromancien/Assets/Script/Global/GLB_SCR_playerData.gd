extends Node

#######################################################
## RESSOURCES :

# la ressource utilisé pour créer des monstres
var composants : int = 0

# la ressource utilisé pour lancer des sorts
var mana : int = 0


########################################################
## REFERENCES :

#Reference a la cible actuel du joueur, en tant que position
var cible : Vector2

#Reference a la base du joueur.
var PlayerBase : Node2D
