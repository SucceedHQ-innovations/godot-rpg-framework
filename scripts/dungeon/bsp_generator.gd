extends Node

class_name BSPDungeonGenerator

@export var dungeon_width := 80
@export var dungeon_height := 60
@export var min_room_size := 5
@export var max_room_size := 12
@export var min_leaf_size := 8
@export var room_padding := 1
@export var corridor_width := 2

var tiles: Array  # 2D array: 0 = wall, 1 = floor, 2 = corridor
var rooms: Array[Rect2i] = []
var corridors: Array[Rect2i] = []

func generate() -> Dictionary:
	tiles = []
	for y in range(dungeon_height):
		tiles.append([])
		for x in range(dungeon_width):
			tiles[y].append(0)

	rooms.clear()
	corridors.clear()

	var root = BSPLeaf.new(Rect2i(0, 0, dungeon_width, dungeon_height), min_leaf_size)
	_split_leaf(root)

	_create_rooms(root)
	_create_corridors(root)

	return {
		"tiles": tiles,
		"rooms": rooms,
		"corridors": corridors,
		"player_spawn": rooms[0].get_center() if rooms.size() > 0 else Vector2i(5, 5),
		"exit_position": rooms[-1].get_center() if rooms.size() > 1 else Vector2i(dungeon_width - 5, dungeon_height - 5)
	}

func _split_leaf(leaf: BSPLeaf) -> void:
	if leaf.rect.size.x < min_leaf_size * 2 and leaf.rect.size.y < min_leaf_size * 2:
		return

	var split_h: bool
	if leaf.rect.size.x > leaf.rect.size.y:
		split_h = false
	elif leaf.rect.size.y > leaf.rect.size.x:
		split_h = true
	else:
		split_h = randi() % 2 == 0

	var max_split = (leaf.rect.size.y if split_h else leaf.rect.size.x) - min_leaf_size
	if max_split <= min_leaf_size:
		return

	var split = min_leaf_size + randi() % (max_split - min_leaf_size)

	if split_h:
		leaf.left = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, leaf.rect.size.x, split))
		leaf.right = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y + split, leaf.rect.size.x, leaf.rect.size.y - split))
	else:
		leaf.left = BSPLeaf.new(Rect2i(leaf.rect.position.x, leaf.rect.position.y, split, leaf.rect.size.y))
		leaf.right = BSPLeaf.new(Rect2i(leaf.rect.position.x + split, leaf.rect.position.y, leaf.rect.size.x - split, leaf.rect.size.y))

	_split_leaf(leaf.left)
	_split_leaf(leaf.right)

func _create_rooms(leaf: BSPLeaf) -> void:
	if leaf.left == null and leaf.right == null:
		var room_width = randi() % (min(max_room_size, leaf.rect.size.x - 2 * room_padding) - min_room_size + 1) + min_room_size
		var room_height = randi() % (min(max_room_size, leaf.rect.size.y - 2 * room_padding) - min_room_size + 1) + min_room_size
		var room_x = leaf.rect.position.x + room_padding + randi() % max(1, leaf.rect.size.x - room_width - 2 * room_padding)
		var room_y = leaf.rect.position.y + room_padding + randi() % max(1, leaf.rect.size.y - room_height - 2 * room_padding)

		var room = Rect2i(room_x, room_y, room_width, room_height)
		rooms.append(room)

		for y in range(room.position.y, room.position.y + room.size.y):
			for x in range(room.position.x, room.position.x + room.size.x):
				if x >= 0 and x < dungeon_width and y >= 0 and y < dungeon_height:
					tiles[y][x] = 1
		return

	if leaf.left != null:
		_create_rooms(leaf.left)
	if leaf.right != null:
		_create_rooms(leaf.right)

func _create_corridors(leaf: BSPLeaf) -> void:
	if leaf.left == null or leaf.right == null:
		return

	_create_corridors(leaf.left)
	_create_corridors(leaf.right)

	var left_rooms = _get_leaf_rooms(leaf.left)
	var right_rooms = _get_leaf_rooms(leaf.right)

	if left_rooms.is_empty() or right_rooms.is_empty():
		return

	var room_a = left_rooms[randi() % left_rooms.size()]
	var room_b = right_rooms[randi() % right_rooms.size()]

	var center_a = room_a.get_center()
	var center_b = room_b.get_center()
	_carve_tunnel(Vector2i(center_a.x, center_a.y), Vector2i(center_b.x, center_b.y))

func _get_leaf_rooms(leaf: BSPLeaf) -> Array[Rect2i]:
	if leaf.left == null and leaf.right == null:
		var result: Array[Rect2i] = []
		for room in rooms:
			if leaf.rect.has_point(room.position):
				result.append(room)
		return result
	var result: Array[Rect2i] = []
	if leaf.left != null:
		result.append_array(_get_leaf_rooms(leaf.left))
	if leaf.right != null:
		result.append_array(_get_leaf_rooms(leaf.right))
	return result

func _carve_tunnel(from: Vector2i, to: Vector2i) -> void:
	var x = from.x
	var y = from.y

	while x != to.x:
		_carve_tile(x, y)
		x += 1 if to.x > x else -1
	while y != to.y:
		_carve_tile(x, y)
		y += 1 if to.y > y else -1
	_carve_tile(x, y)

func _carve_tile(x: int, y: int) -> void:
	for dx in range(corridor_width):
		for dy in range(corridor_width):
			var tx = x + dx - corridor_width / 2
			var ty = y + dy - corridor_width / 2
			if tx >= 0 and tx < dungeon_width and ty >= 0 and ty < dungeon_height:
				if tiles[ty][tx] == 0:
					tiles[ty][tx] = 2


class BSPLeaf:
	var rect: Rect2i
	var left: BSPLeaf = null
	var right: BSPLeaf = null

	func _init(r: Rect2i, _min_size: int):
		rect = r
