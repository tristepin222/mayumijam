
extends PlayerAbility

@export var bonus_damage: int = 20
@export var hits_to_crack: int = 5
@export var stagger_duration: float = 1.5

var successful_hits := 0


func _ready() -> void:
	ability_id = AbilityIDs.Ability.SHATTERING_BLOW


func register_sword_hit(saki: SakiController, enemy_stats: CharacterStats) -> void:
	if not can_activate():
		return

	if saki.is_cracked:
		enemy_stats.take_damage(bonus_damage)
		saki.break_crack(stagger_duration)

		print("Shattering Blow! Bonus damage: ", bonus_damage)
		return

	successful_hits += 1

	print("Shattering Blow counter: ", successful_hits, "/", hits_to_crack)

	if successful_hits >= hits_to_crack:
		successful_hits = 0
		saki.crack()
