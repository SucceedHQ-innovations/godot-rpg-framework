extends Node

class_name CombatSystem

signal damage_dealt(source, target, amount)
signal unit_died(unit)
signal status_applied(unit, effect)
signal status_expired(unit, effect)

const DAMAGE_FORMULA = preload("res://scripts/combat/damage_formula.gd")

var entities := {}
var status_effects := {}

func register_entity(entity: Node, stats: Dictionary) -> void:
	entities[entity] = {
		"stats": stats,
		"statuses": [],
		"cooldowns": {}
	}

func unregister_entity(entity: Node) -> void:
	entities.erase(entity)

func deal_damage(source: Node, target: Node, skill: Dictionary) -> Dictionary:
	if not _validate_combatants(source, target):
		return {"success": false, "reason": "Invalid combatants"}

	var source_data = entities[source]
	var target_data = entities[target]
	var result = DAMAGE_FORMULA.calculate(source_data.stats, target_data.stats, skill)

	target_data.stats.health -= result.damage
	result.actual_damage = result.damage
	damage_dealt.emit(source, target, result.damage)

	if target_data.stats.health <= 0:
		target_data.stats.health = 0
		unit_died.emit(target)
		result.killed = true

	_apply_on_hit_effects(source, target, result)
	return result

func apply_status(target: Node, effect: StatusEffect) -> void:
	if not entities.has(target):
		return
	var data = entities[target]
	var existing = data.statuses.find(func(s): return s.effect_id == effect.effect_id)
	if existing != null:
		existing.refresh(effect)
	else:
		var instance = effect.duplicate()
		data.statuses.append(instance)
		instance.applied.connect(_on_status_applied.bind(target))
		instance.expired.connect(_on_status_expired.bind(target))
		instance.apply(target)
	status_applied.emit(target, effect)

func _process(delta: float) -> void:
	for entity in entities:
		var data = entities[entity]
		var expired = []
		for status in data.statuses:
			status.tick(delta)
			if status.is_expired():
				expired.append(status)
		for status in expired:
			status.expire()
			data.statuses.erase(status)

func _validate_combatants(source: Node, target: Node) -> bool:
	return entities.has(source) and entities.has(target) and \
		   entities[source].stats.health > 0 and entities[target].stats.health > 0

func _on_status_applied(effect: StatusEffect, target: Node) -> void:
	pass

func _on_status_expired(effect: StatusEffect, target: Node) -> void:
	status_expired.emit(target, effect)

func _apply_on_hit_effects(source: Node, target: Node, result: Dictionary) -> void:
	if result.has("status_effects"):
		for effect in result.status_effects:
			apply_status(target, effect)

func get_stats(entity: Node) -> Dictionary:
	return entities.get(entity, {}).get("stats", {})

func has_status(entity: Node, effect_id: String) -> bool:
	var data = entities.get(entity)
	if not data:
		return false
	return data.statuses.any(func(s): return s.effect_id == effect_id)
