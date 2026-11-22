class_name GameSettings
extends RefCounted

const SETTINGS_PATH = "user://settings.cfg"

static var master_volume: float = 1.0
static var music_volume: float = 0.8
static var sfx_volume: float = 0.9
static var fullscreen: bool = false


static func load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(SETTINGS_PATH) != OK:
		return

	master_volume = clampf(config.get_value("audio", "master", master_volume), 0.0, 1.0)
	music_volume = clampf(config.get_value("audio", "music", music_volume), 0.0, 1.0)
	sfx_volume = clampf(config.get_value("audio", "sfx", sfx_volume), 0.0, 1.0)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)


static func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)


static func apply(tree: SceneTree) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)

	if tree != null:
		var music := tree.root.get_node_or_null("MusicManager")

		if music != null and music.has_method("set_music_volume"):
			music.set_music_volume(music_volume)

		if music != null and music.has_method("set_sfx_volume"):
			music.set_sfx_volume(sfx_volume)

	apply_window_mode()


static func apply_window_mode() -> void:
	if OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return

	var target := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	var current := DisplayServer.window_get_mode()
	var is_fullscreen := current == DisplayServer.WINDOW_MODE_FULLSCREEN or current == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

	if fullscreen != is_fullscreen:
		DisplayServer.window_set_mode(target)
