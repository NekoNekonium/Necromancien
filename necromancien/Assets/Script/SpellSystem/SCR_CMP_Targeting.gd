extends Node
class_name CMP_Targeting

# mode indicating the type of target the spell
enum TargetMode {location, entity, area, everything}
@export var spellTargetMode : TargetMode = TargetMode.location
@export var spellAreaSize : float = 0

# mode indicating what entites are affected by the spell
enum FilterMode {everyone, none, allies, ennemies}
@export var spellFilterMode : FilterMode = FilterMode.everyone
