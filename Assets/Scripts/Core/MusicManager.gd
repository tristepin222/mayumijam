extends Node

const TRACKS = {
	"main_menu": "res://Assets/Audio/Music/main_menu.ogg",
	"keiki_theme_1": "res://Assets/Audio/Music/keiki_theme_1.ogg",
	"keiki_theme_2": "res://Assets/Audio/Music/keiki_theme_2.ogg",
	"keiki_theme_final": "res://Assets/Audio/Music/keiki_theme_final.ogg",
	"final_phase": "res://Assets/Audio/Music/final_phase.ogg",
	"final_cutscene": "res://Assets/Audio/Music/final_cutscene.ogg",
	"shop_cold": "res://Assets/Audio/Music/shop_cold.ogg",
	"shop_warm": "res://Assets/Audio/Music/shop_warm.ogg",
}

const SFX_BUS := "SFX"
const SFX_ROOT := "res://Assets/Audio/SFX/"

const SFX_VOLUMES = {
	"sword_swing": -10.0,
	"sword_hit": -4.0,
	"clay_crush": -2.0,
	"mayumi_death": 0.0,
	"jump": -8.0,
	"double_jump": -7.0,
	"land": -10.0,
	"dash": -6.0,
	"graze": -6.0,
	"arrow": -6.0,
	"charge_up": -8.0,
	"shatter": -3.0,
	"telegraph": -8.0,
	"fire_burst": -12.0,
	"earth_rumble": -6.0,
	"earth_impact": -6.0,
	"punch": -3.0,
	"wolf_howl": -4.0,
	"furnace_loop": -18.0,
	"menu_select": -6.0,
	"menu_back": -6.0,
}

const SFX_ALIASES = {
	"sword_swing": "dash",
}

@export var volume_db: float = -6.0
@export var fade_time: float = 1.0
@export var sfx_voices: int = 16

var players: Array[AudioStreamPlayer] = []
var active_index := 0
var current_track := ""
var music_volume := 1.0

var sfx_players: Array[AudioStreamPlayer] = []
var sfx_next := 0
var sfx_streams: Dictionary = {}
var sfx_loops: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.volume_db = -80.0
		add_child(player)
		players.append(player)

	_create_sfx_bus()

	for i in range(sfx_voices):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = SFX_BUS
		add_child(sfx_player)
		sfx_players.append(sfx_player)

	GameSettings.load_settings()
	GameSettings.apply(get_tree())


func play(track: String, start_at: float = 0.0) -> void:
	if track == current_track:
		return

	if not TRACKS.has(track):
		push_warning("MusicManager: Unknown track '%s'." % track)
		return

	var stream := load(TRACKS[track]) as AudioStream

	if stream == null:
		push_warning("MusicManager: Could not load '%s'." % TRACKS[track])
		return

	if "loop" in stream:
		stream.set("loop", true)

	current_track = track

	var old_player := players[active_index]
	active_index = 1 - active_index
	var new_player := players[active_index]

	new_player.stream = stream
	new_player.volume_db = -40.0
	new_player.play(start_at)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(new_player, "volume_db", _target_db(), fade_time)

	if old_player.playing:
		tween.tween_property(old_player, "volume_db", -60.0, fade_time)
		tween.chain().tween_callback(_stop_if_inactive.bind(old_player))


func _create_sfx_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS) >= 0:
		return

	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, SFX_BUS)
	AudioServer.set_bus_send(index, "Master")


func set_sfx_volume(linear: float) -> void:
	var index := AudioServer.get_bus_index(SFX_BUS)

	if index < 0:
		return

	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.0)


func play_sfx(sound: String, volume_offset: float = 0.0, pitch: float = 1.0, pitch_variation: float = 0.05) -> AudioStreamPlayer:
	var stream := _get_sfx_stream(sound)

	if stream == null:
		return null

	var player := sfx_players[sfx_next]
	sfx_next = (sfx_next + 1) % sfx_players.size()

	player.stop()
	player.stream = stream
	player.volume_db = SFX_VOLUMES.get(sound, 0.0) + volume_offset
	player.pitch_scale = maxf(pitch + randf_range(-pitch_variation, pitch_variation), 0.05)
	player.play()
	return player


func stop_sfx(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player):
		player.stop()


func start_sfx_loop(sound: String, volume_offset: float = 0.0) -> void:
	if sfx_loops.has(sound):
		return

	var stream := _get_sfx_stream(sound)

	if stream == null:
		return

	var loop_stream := stream.duplicate() as AudioStream

	if "loop" in loop_stream:
		loop_stream.set("loop", true)

	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = loop_stream
	player.volume_db = -40.0
	add_child(player)
	player.play()
	sfx_loops[sound] = player

	create_tween().tween_property(player, "volume_db", SFX_VOLUMES.get(sound, 0.0) + volume_offset, 0.6)


func stop_sfx_loop(sound: String) -> void:
	if not sfx_loops.has(sound):
		return

	var player: AudioStreamPlayer = sfx_loops[sound]
	sfx_loops.erase(sound)

	var tween := create_tween()
	tween.tween_property(player, "volume_db", -40.0, 0.4)
	tween.tween_callback(player.queue_free)


func _get_sfx_stream(sound: String) -> AudioStream:
	var file_name: String = SFX_ALIASES.get(sound, sound)

	if not sfx_streams.has(file_name):
		var path := SFX_ROOT + file_name + ".ogg"
		sfx_streams[file_name] = load(path) if ResourceLoader.exists(path) else null

	return sfx_streams[file_name]


func set_music_volume(linear: float) -> void:
	music_volume = clampf(linear, 0.0, 1.0)

	var player := players[active_index] if players.size() > active_index else null

	if player != null and player.playing:
		player.volume_db = _target_db()


func _target_db() -> float:
	if music_volume <= 0.0:
		return -80.0

	return volume_db + linear_to_db(music_volume)


func stop() -> void:
	current_track = ""

	for player in players:
		if player.playing:
			var tween := create_tween()
			tween.tween_property(player, "volume_db", -60.0, fade_time)
			tween.tween_callback(player.stop)


func _stop_if_inactive(player: AudioStreamPlayer) -> void:
	if player != players[active_index]:
		player.stop()
