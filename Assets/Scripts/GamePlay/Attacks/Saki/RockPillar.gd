class_name RockPillar
extends Sprite2D

const TEXTURE_PATHS := [
	"res://Assets/Textures/Rocks/rock_pillar_0.png",
	"res://Assets/Textures/Rocks/rock_pillar_1.png",
	"res://Assets/Textures/Rocks/rock_pillar_2.png",
]

var target_scale := 1.0
var rise_delay := 0.0
var rise_time := 0.12
var sink_time := 0.15


static func create(height: float, delay: float = 0.0) -> RockPillar:
	var rock := RockPillar.new()
	rock.texture = load(TEXTURE_PATHS.pick_random())
	rock.offset = Vector2(0.0, -rock.texture.get_height() * 0.5)
	rock.target_scale = height / float(rock.texture.get_height())
	rock.rise_delay = delay
	rock.flip_h = randf() < 0.5
	return rock


func _ready() -> void:
	scale = Vector2(target_scale * 1.2, 0.0)

	var tween := create_tween()

	if rise_delay > 0.0:
		tween.tween_interval(rise_delay)

	tween.tween_property(self, "scale", Vector2(target_scale * 0.95, target_scale * 1.12), rise_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * target_scale, 0.06)


func retract() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(target_scale * 1.15, 0.0), sink_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
