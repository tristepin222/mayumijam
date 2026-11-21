extends Resource
class_name DialogLine

@export var character: DialogManager.characters 
@export var portrait_coords: Vector2 = Vector2.ZERO 
@export_multiline var text: String = ""

@export_group("Special Actions")
@export var animation_name: String = ""
