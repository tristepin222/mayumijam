class_name PortraitLibrary
extends RefCounted

const ROOT := "res://Assets/Textures/Portraits/"

const MAYUMI_FORMS := ["ghost", "mid", "armor"]

const MAYUMI := {
	"ghost": {
		"normal": ["neutral", "brooding", "surprised", "angry"],
		"damaged": ["neutral", "brooding", "confused", "pained"],
	},
	"mid": {
		"normal": ["neutral", "brooding", "surprised", "angry", "determined", "happy", "pained", "thinking"],
		"damaged": ["neutral", "brooding", "confused", "pained", "angry", "smiling", "surprised"],
	},
	"armor": {
		"normal": ["neutral", "angry", "blushing", "determined", "surprised"],
		"damaged": ["determined"],
	},
}

const SAKI := {
	"normal": ["neutral", "angry", "annoyed", "cocky", "dismissive", "eager", "laugh", "surprised"],
	"damaged": ["angry", "annoyed", "eager"],
	"p2": ["p2_fired_up", "p2_furious"],
}

const KEIKI := {
	"work": ["neutral", "apologetic", "confused", "excited", "happy", "surprised", "sweating", "thinking", "unsure"],
	"goddess": ["determined", "determined_2"],
}

const FALLBACKS := {
	"neutral": ["neutral", "determined", "annoyed", "brooding"],
	"angry": ["angry", "annoyed", "pained", "determined", "brooding", "neutral"],
	"shouting": ["angry", "determined", "neutral"],
	"annoyed": ["annoyed", "angry", "brooding", "neutral"],
	"brooding": ["brooding", "thinking", "neutral", "annoyed", "determined"],
	"thinking": ["thinking", "brooding", "neutral", "determined"],
	"confused": ["confused", "surprised", "unsure", "neutral", "annoyed", "determined"],
	"surprised": ["surprised", "confused", "angry", "neutral", "determined"],
	"pained": ["pained", "brooding", "neutral", "annoyed", "determined"],
	"determined": ["determined", "neutral", "angry", "annoyed"],
	"happy": ["happy", "smiling", "excited", "neutral", "eager", "determined"],
	"smiling": ["smiling", "happy", "neutral", "eager", "determined"],
	"blushing": ["blushing", "happy", "smiling", "surprised", "neutral", "determined"],
	"excited": ["excited", "happy", "eager", "determined_2", "neutral", "determined"],
	"eager": ["eager", "laugh", "cocky", "angry", "neutral"],
	"cocky": ["cocky", "eager", "laugh", "dismissive", "annoyed", "neutral"],
	"laugh": ["laugh", "eager", "cocky", "annoyed", "neutral"],
	"dismissive": ["dismissive", "annoyed", "cocky", "neutral"],
	"apologetic": ["apologetic", "sweating", "unsure", "neutral", "determined"],
	"sweating": ["sweating", "unsure", "apologetic", "neutral", "determined"],
	"unsure": ["unsure", "sweating", "thinking", "neutral", "determined"],
}

static var _cache := {}


static func mayumi_form_for_act(act: int) -> String:
	return MAYUMI_FORMS[clampi(act, 0, MAYUMI_FORMS.size() - 1)]


static func get_portrait(character: int, emotion: String, context: Dictionary, on_left_side: bool) -> Texture2D:
	var path := get_portrait_path(character, emotion, context, on_left_side)

	if path.is_empty():
		return null

	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null

	return _cache[path]


static func get_portrait_path(character: int, emotion: String, context: Dictionary, on_left_side: bool) -> String:
	var mood := emotion.to_lower().strip_edges()

	if mood.is_empty():
		mood = "neutral"

	match character:
		DialogManager.characters.MAYUMI:
			var form: String = context.get("mayumi_form", "ghost")

			if not MAYUMI.has(form):
				form = "ghost"

			if context.get("mayumi_damaged", false):
				var damaged := _pick(MAYUMI[form]["damaged"], mood)
				return ROOT + "Mayumi/%s/damaged_%s.png" % [form, damaged]

			return ROOT + "Mayumi/%s/%s.png" % [form, _pick(MAYUMI[form]["normal"], mood)]

		DialogManager.characters.SAKI:
			if mood.begins_with("p2_"):
				return ROOT + "Saki/%s.png" % _pick(SAKI["p2"], mood)

			if context.get("saki_damaged", false):
				return ROOT + "Saki/damaged_%s.png" % _pick(SAKI["damaged"], mood)

			return ROOT + "Saki/%s.png" % _pick(SAKI["normal"], mood)

		DialogManager.characters.KEIKI:
			if mood == "shop":
				return ROOT + "Keiki/shop.png"

			if context.get("keiki_outfit", "work") == "goddess":
				var side := "left" if on_left_side else "right"
				return ROOT + "Keiki/goddess_%s_%s.png" % [side, _pick(KEIKI["goddess"], mood)]

			return ROOT + "Keiki/work_%s.png" % _pick(KEIKI["work"], mood)

	return ""


static func _pick(available: Array, mood: String) -> String:
	if available.has(mood):
		return mood

	for candidate in FALLBACKS.get(mood, ["neutral"]):
		if available.has(candidate):
			return candidate

	return available[0]
