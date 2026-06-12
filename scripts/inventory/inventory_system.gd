extends Node

class_name InventorySystem

signal item_added(item_id: String, slot: Vector2i)
signal item_removed(item_id: String, slot: Vector2i)
signal inventory_changed

const GRID_WIDTH := 10
const GRID_HEIGHT := 6

var grid: Array  # 2D array of InventorySlot
var items: Dictionary = {}  # item_id -> ItemData
var equipped: Dictionary = {}  # slot_name -> item_id
var gold := 0

func _init():
	grid = []
	for y in range(GRID_HEIGHT):
		grid.append([])
		for x in range(GRID_WIDTH):
			grid[y].append(InventorySlot.new())

func add_item(item_data: ItemData) -> bool:
	var positions = _find_available_space(item_data.size)
	if positions.is_empty():
		return false

	var item_id = _generate_item_id()
	items[item_id] = item_data

	for pos in positions:
		grid[pos.y][pos.x].occupied = true
		grid[pos.y][pos.x].item_id = item_id

	item_added.emit(item_id, positions[0])
	return true

func remove_item(slot: Vector2i) -> ItemData:
	var slot_data = grid[slot.y][slot.x]
	if not slot_data.occupied:
		return null

	var item_id = slot_data.item_id
	var item = items[item_id]
	var item_slots = _get_item_slots(item_id)

	for s in item_slots:
		grid[s.y][s.x].occupied = false
		grid[s.y][s.x].item_id = ""

	items.erase(item_id)
	item_removed.emit(item_id, slot)
	inventory_changed.emit()
	return item

func equip(item_id: String, slot_name: String) -> bool:
	if not items.has(item_id):
		return false
	var item = items[item_id]
	if not item.equippable:
		return false
	if not slot_name in item.equippable_slots:
		return false
	if equipped.has(slot_name):
		unequip(slot_name)
	equipped[slot_name] = item_id
	inventory_changed.emit()
	return true

func unequip(slot_name: String) -> void:
	equipped.erase(slot_name)
	inventory_changed.emit()

func has_item(item_id: String) -> bool:
	return items.values().any(func(i): return i.item_id == item_id)

func get_item_count(item_id: String) -> int:
	return items.values().reduce(func(count, i): return count + (1 if i.item_id == item_id else 0), 0)

func use_item(item_id: String, target: Node) -> bool:
	if not items.has(item_id):
		return false
	var item = items[item_id]
	if not item.usable:
		return false
	item.use_function.call(target)
	return true

func _find_available_space(size: Vector2i) -> Array[Vector2i]:
	for y in range(GRID_HEIGHT - size.y + 1):
		for x in range(GRID_WIDTH - size.x + 1):
			if _is_space_free(Vector2i(x, y), size):
				var positions: Array[Vector2i] = []
				for dy in range(size.y):
					for dx in range(size.x):
						positions.append(Vector2i(x + dx, y + dy))
				return positions
	return []

func _is_space_free(start: Vector2i, size: Vector2i) -> bool:
	for y in range(start.y, start.y + size.y):
		for x in range(start.x, start.x + size.x):
			if grid[y][x].occupied:
				return false
	return true

func _get_item_slots(item_id: String) -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x].item_id == item_id:
				slots.append(Vector2i(x, y))
	return slots

func _generate_item_id() -> String:
	return "item_" + str(Time.get_ticks_usec()) + "_" + str(randi())

func add_gold(amount: int) -> void:
	gold += amount
	inventory_changed.emit()

func remove_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	inventory_changed.emit()
	return true


class InventorySlot:
	var occupied: bool = false
	var item_id: String = ""


class ItemData:
	var item_id: String
	var item_name: String
	var description: String
	var icon_path: String
	var size: Vector2i = Vector2i(1, 1)
	var stackable: bool = false
	var max_stack: int = 1
	var equippable: bool = false
	var equippable_slots: Array[String] = []
	var usable: bool = false
	var use_function: Callable
	var value: int = 0
	var rarity: String = "common"
	var stats: Dictionary = {}
