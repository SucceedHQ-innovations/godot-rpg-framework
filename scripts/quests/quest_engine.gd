extends Node

class_name QuestEngine

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

var active_quests: Dictionary = {}  # quest_id -> QuestInstance
var completed_quests: Array[String] = []
var quest_definitions: Dictionary = {}  # quest_id -> QuestDefinition


func register_quest(definition: QuestDefinition) -> void:
	quest_definitions[definition.quest_id] = definition

func start_quest(quest_id: String) -> bool:
	if not quest_definitions.has(quest_id):
		return false
	if active_quests.has(quest_id):
		return false
	if completed_quests.has(quest_id) and not quest_definitions[quest_id].repeatable:
		return false

	var def = quest_definitions[quest_id]
	if not _check_prerequisites(def):
		return false

	var instance = QuestInstance.new()
	instance.definition = def
	for i in range(def.objectives.size()):
		instance.objective_progress.append(0)
	active_quests[quest_id] = instance
	quest_started.emit(quest_id)
	return true

func _check_prerequisites(def: QuestDefinition) -> bool:
	for prereq in def.prerequisites:
		if not completed_quests.has(prereq):
			return false
	return true

func advance_objective(quest_id: String, objective_index: int, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return

	var instance = active_quests[quest_id]
	if objective_index >= instance.objective_progress.size():
		return

	if instance.objective_progress[objective_index] >= instance.definition.objectives[objective_index].target:
		return

	instance.objective_progress[objective_index] = min(
		instance.objective_progress[objective_index] + amount,
		instance.definition.objectives[objective_index].target
	)
	quest_updated.emit(quest_id, objective_index)

	if _check_completion(quest_id):
		_complete_quest(quest_id)

func fail_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	active_quests.erase(quest_id)
	quest_failed.emit(quest_id)

func _check_completion(quest_id: String) -> bool:
	var instance = active_quests[quest_id]
	for i in range(instance.objective_progress.size()):
		if instance.objective_progress[i] < instance.definition.objectives[i].target:
			return false
	return true

func _complete_quest(quest_id: String) -> void:
	var instance = active_quests[quest_id]
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	_grant_rewards(instance.definition)
	quest_completed.emit(quest_id)

func _grant_rewards(def: QuestDefinition) -> void:
	for reward in def.rewards:
		match reward.type:
			"experience":
				ExperienceSystem.add_experience(reward.amount)
			"item":
				InventorySystem.add_item(reward.data)
			"gold":
				InventorySystem.add_gold(reward.amount)

func get_quest_state(quest_id: String) -> Dictionary:
	if active_quests.has(quest_id):
		var inst = active_quests[quest_id]
		return {
			"state": "active",
			"objectives": inst.objective_progress,
			"definition": inst.definition
		}
	if completed_quests.has(quest_id):
		return {"state": "completed"}
	if quest_definitions.has(quest_id):
		return {"state": "available"}
	return {"state": "unknown"}


class QuestDefinition:
	var quest_id: String
	var quest_name: String
	var description: String
	var objectives: Array[QuestObjective] = []
	var prerequisites: Array[String] = []
	var rewards: Array[QuestReward] = []
	var repeatable: bool = false
	var time_limit: float = 0.0
	var failure_conditions: Array[String] = []


class QuestObjective:
	var description: String
	var target: int = 1
	var current: int = 0
	var objective_type: String = "kill"  # kill, collect, talk, explore, escort


class QuestReward:
	var type: String  # experience, item, gold
	var amount: int = 0
	var data  # optional extra data


class QuestInstance:
	var definition: QuestDefinition
	var objective_progress: Array[int] = []
	var time_remaining: float = 0.0
	var started_at: int
