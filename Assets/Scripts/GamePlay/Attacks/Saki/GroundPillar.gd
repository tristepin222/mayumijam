extends Area2D

@export var pillar_height: float = 48.0
@export var ground_sink: float = 4.0

var rock: RockPillar


func _ready() -> void:
	rock = RockPillar.create(pillar_height)
	rock.position = Vector2(0.0, ground_sink)
	add_child(rock)


func retract() -> void:
	set_deferred("monitoring", false)

	if is_instance_valid(rock):
		rock.retract()
		await get_tree().create_timer(rock.sink_time + 0.02, false).timeout

	queue_free()
