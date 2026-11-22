class_name Sfx
extends RefCounted


static func play(sound: String, volume_offset: float = 0.0, pitch: float = 1.0, pitch_variation: float = 0.05) -> AudioStreamPlayer:
	var manager := _manager()

	if manager == null:
		return null

	return manager.play_sfx(sound, volume_offset, pitch, pitch_variation)


static func stop(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()


static func start_loop(sound: String, volume_offset: float = 0.0) -> void:
	var manager := _manager()

	if manager != null:
		manager.start_sfx_loop(sound, volume_offset)


static func stop_loop(sound: String) -> void:
	var manager := _manager()

	if manager != null:
		manager.stop_sfx_loop(sound)


static func _manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree

	if tree == null:
		return null

	return tree.root.get_node_or_null("MusicManager")
