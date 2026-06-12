extends Resource

class_name DialogueGraph

@export var title: String = "New Dialogue"
@export var nodes: Array[DialogueNode] = []

signal graph_changed

func add_node(node: DialogueNode) -> void:
	nodes.append(node)
	graph_changed.emit()

func remove_node(node: DialogueNode) -> void:
	nodes.erase(node)
	disconnect_node(node)
	graph_changed.emit()

func connect_node(from: DialogueNode, from_port: int, to: DialogueNode) -> void:
	if from.outputs.size() <= from_port:
		return
	from.outputs[from_port].target_node_id = to.node_id
	graph_changed.emit()

func disconnect_node(node: DialogueNode) -> void:
	for n in nodes:
		for output in n.outputs:
			if output.target_node_id == node.node_id:
				output.target_node_id = ""

func get_node_by_id(node_id: String) -> DialogueNode:
	for node in nodes:
		if node.node_id == node_id:
			return node
	return null

func get_start_node() -> DialogueNode:
	for node in nodes:
		if node.node_type == DialogueNode.NodeType.START:
			return node
	return null

func resolve_conditions(context: Dictionary) -> DialogueNode:
	var start = get_start_node()
	if not start:
		return null
	return _traverse(start, context)

func _traverse(node: DialogueNode, context: Dictionary) -> DialogueNode:
	if node.node_type == DialogueNode.NodeType.END:
		return node
	if node.outputs.is_empty():
		return node

	for output in node.outputs:
		if output.condition.is_empty() or _evaluate_condition(output.condition, context):
			var target = get_node_by_id(output.target_node_id)
			if target:
				return _traverse(target, context)

	return node

func _evaluate_condition(condition: String, context: Dictionary) -> bool:
	if condition.is_empty():
		return true
	var parts = condition.split(" ")
	if parts.size() < 3:
		return false

	var var_name = parts[0]
	var operator = parts[1]
	var value = parts[2]

	if not context.has(var_name):
		return false

	var context_value = context[var_name]
	match operator:
		"==":
			return str(context_value) == value
		"!=":
			return str(context_value) != value
		">":
			return float(context_value) > float(value)
		"<":
			return float(context_value) < float(value)
		">=":
			return float(context_value) >= float(value)
		"<=":
			return float(context_value) <= float(value)
		"has_item":
			return context.get("inventory", {}).has(value)
	return true


class DialogueNode:
	enum NodeType { START, DIALOGUE, CHOICE, CONDITION, ACTION, END }

	var node_id: String
	var node_type: NodeType = NodeType.DIALOGUE
	var speaker: String = ""
	var text: String = ""
	var outputs: Array[Output] = []

	class Output:
		var label: String = ""
		var condition: String = ""
		var target_node_id: String = ""
