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

@export var volume_db: float = -6.0
@export var fade_time: float = 1.0

var players: Array[AudioStreamPlayer] = []
var active_index := 0
var current_track := ""
var music_volume := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for i in range(2):
		var player := AudioStreamPlayer.new()
		player.volume_db = -80.0
		add_child(player)
		players.append(player)

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
