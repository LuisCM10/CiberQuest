extends Node2D

# =============================================================
# FlowControl

const INF := 999999

# Matriz
var capacity = [
	[0, 16, 13, 0, 0, 0],
	[0, 0, 10, 12, 0, 0],
	[0, 4, 0, 0, 14, 0],
	[0, 0, 9, 0, 0, 20],
	[0, 0, 0, 7, 0, 4],
	[0, 0, 0, 0, 0, 0]
]

var original_capacity = []
var V := 6
var flow_network = []
var residual_graph = []
var nodes_pos = []
var edge_nodes = []
var source := -1
var sink := -1

# Variables 
var selecting_source := true
var current_path = []
var selected_node = -1
var total_flow_sent := 0
var target_flow := 0
var time_remaining := 300.0
var game_started := false
var game_over := false
var packets_sent := 0
var nemesis_attacks := 0
var nemesis_active := false

@onready var graph_container = $GraphContainer
@onready var ui_panel = $UI/Panel
@onready var instructions = $UI/Panel/Instructions
@onready var stats_label = $UI/Panel/Stats
@onready var path_info = $UI/Panel/PathInfo
@onready var start_button = $UI/Panel/StartButton
@onready var send_button = $UI/Panel/SendButton
@onready var clear_button = $UI/Panel/ClearButton
@onready var timer_label = $UI/Panel/Timer
@onready var boton_ayuda = $UI/BotonAyuda
@onready var panel_ayuda = $UI/Panel/PanelAyuda
@onready var label_explicacion = $UI/Panel/PanelAyuda/LabelExplicacion
@onready var boton_continuar = $UI/Panel/PanelAyuda/BotonContinuar
@onready var panelCiber = $UI/Panel/PanelCiber
@onready var lExplicaCiber = $UI/Panel/PanelCiber/ExplicaCiber
@onready var boton_continuar2 = $UI/Panel/PanelCiber/BotonContinuar2

var base_resolution := Vector2(480, 270)
func _ready():
	panelCiber.visible = true
func _iniciar_mision():
	randomize()
	_setup_ui()
	
	start_button.pressed.connect(_on_start_pressed)
	send_button.pressed.connect(_on_send_flow_pressed)
	clear_button.pressed.connect(_on_clear_path_pressed)
	send_button.disabled = true
	panel_ayuda.visible = false
	
	_update_instructions("Presiona [Iniciar] para comenzar")
	_initialize_flow_network()
	_draw_fixed_graph()

	
func _initialize_flow_network():
	# Guardar capacidades originales
	original_capacity.clear()
	for i in range(V):
		var row = []
		for j in range(V):
			row.append(capacity[i][j])
		original_capacity.append(row)
	
	# Inicializar flujo en 0
	flow_network.clear()
	for i in range(V):
		var row = []
		for j in range(V):
			row.append(0)
		flow_network.append(row)
	
	# Inicializar grafo residual = capacidad original(matrices)
	residual_graph.clear()
	for i in range(V):
		var row = []
		for j in range(V):
			row.append(capacity[i][j])
		residual_graph.append(row)

func _setup_ui():
	
	stats_label.text = "Flujo: 0/? | Paquetes: 0"
	stats_label.add_theme_font_size_override("font_size", 12)
	
	path_info.text = "Inicio: ? | Destino: ?"
	path_info.add_theme_font_size_override("font_size", 12)
	
	timer_label.text = "Tiempo: --:--"
	timer_label.add_theme_font_size_override("font_size", 12)
	
	instructions.add_theme_font_size_override("font_size", 12)
	
	send_button.text = "Enviar"
	send_button.add_theme_font_size_override("font_size", 12)
	
	clear_button.text = "Limpiar"
	clear_button.add_theme_font_size_override("font_size", 12)
	
	start_button.text = "Iniciar"
	start_button.add_theme_font_size_override("font_size", 12)

func _process(delta):
	if game_started and !game_over:
		time_remaining -= delta
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]
		
		if time_remaining < 30:
			timer_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		
		if time_remaining <= 0:
			_game_over(false)
		
		if randf() < 0.0005 and !nemesis_active:
			_nemesis_attack()

# Dibujo del grafo
func _draw_fixed_graph():
	for child in graph_container.get_children():
		child.queue_free()
	edge_nodes.clear()
	nodes_pos.clear()

	# Posiciones
	nodes_pos = [
		Vector2(60, 135),    # 0 (izquierda-centro)
		Vector2(160, 70),    # 1 (arriba)
		Vector2(160, 200),   # 2 (abajo)
		Vector2(280, 90),    # 3 (medio-arriba)
		Vector2(280, 180),   # 4 (medio-abajo)
		Vector2(400, 135)    # 5 (derecha-centro)
	]

	#Aristas
	var drawn_edges = {}
	for u in range(V):
		for v in range(V):
			if original_capacity[u][v] > 0:
				var edge_key = str(min(u, v)) + "_" + str(max(u, v))
				
				if original_capacity[v][u] > 0 and not drawn_edges.has(edge_key):
					_create_bidirectional_edge(u, v)
					drawn_edges[edge_key] = true
				elif original_capacity[v][u] == 0:
					_create_edge(u, v)

	# Nodos 
	for i in range(V):
		_create_node(i)
	
	await get_tree().process_frame

func _create_node(index: int):
	var node = Control.new()
	node.position = nodes_pos[index] - Vector2(20, 20)
	node.custom_minimum_size = Vector2(40, 40)
	node.z_index = 10
	node.name = "Node_" + str(index)

	var outer_circle = _create_circle_sprite(20, Color(0.55, 0.35, 0.2, 0.8))
	outer_circle.position = Vector2(0, 0)
	node.add_child(outer_circle)

	var circle = _create_circle_sprite(17, Color(0.75, 0.55, 0.35))
	circle.position = Vector2(3, 3)
	circle.name = "Circle"
	node.add_child(circle)

	var highlight = _create_circle_sprite(8, Color(0.9, 0.8, 0.5, 0.3))
	highlight.position = Vector2(12, 12)
	highlight.name = "Highlight"
	node.add_child(highlight)

	var label = Label.new()
	label.text = str(index)
	label.position = Vector2(14, 12)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	node.add_child(label)

	var button = Button.new()
	button.custom_minimum_size = Vector2(40, 40)
	button.position = Vector2(0, 0)
	button.flat = true
	button.modulate.a = 0.0
	button.pressed.connect(_on_node_button_pressed.bind(index, circle))
	node.add_child(button)
	
	graph_container.add_child(node)

func _create_circle_sprite(radius: float, color: Color) -> ColorRect:
	var circle = ColorRect.new()
	circle.custom_minimum_size = Vector2(radius * 2, radius * 2)
	circle.position = Vector2(-radius, -radius)
	circle.color = color
	
	var shader_code = """
shader_type canvas_item;

uniform vec4 circle_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	
	if (dist > 0.5) {
		COLOR.a = 0.0;
	} else {
		COLOR = circle_color;
		float edge = smoothstep(0.5, 0.48, dist);
		COLOR.a *= edge;
	}
}
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	
	var material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("circle_color", color)
	
	circle.material = material
	return circle

func _create_edge(u: int, v: int):
	var points = _get_arrow_points(nodes_pos[u], nodes_pos[v], 20.0)
	var start_point = points[0]
	var end_point = points[1]

	var base_color = Color(0.75, 0.55, 0.35) # marrón claro
	var line = Line2D.new()
	line.width = 2
	line.default_color = base_color
	line.points = [start_point, end_point]
	line.z_index = 1
	graph_container.add_child(line)

	_draw_arrow_head(end_point, (end_point - start_point).normalized(), base_color)

	var lbl_node = Control.new()
	lbl_node.position = (start_point + end_point) / 2 - Vector2(20, 15)
	lbl_node.z_index = 20
	lbl_node.custom_minimum_size = Vector2(40, 20)
	graph_container.add_child(lbl_node)

	var lbl = Label.new()
	lbl.text = "0/%d (0)" % capacity[u][v]
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_node.add_child(lbl)

	edge_nodes.append({
		"from": u,
		"to": v,
		"cap": capacity[u][v],
		"line": line,
		"label_node": lbl_node,
		"label": lbl,
		"color_base": base_color
	})

func _draw_arrow_head(pos: Vector2, dir: Vector2, color: Color):
	var arrow_size = 10.0
	var left = pos - dir.rotated(deg_to_rad(25)) * arrow_size
	var right = pos - dir.rotated(deg_to_rad(-25)) * arrow_size

	var arrow_left = Line2D.new()
	arrow_left.width = 2
	arrow_left.default_color = color
	arrow_left.points = [pos, left]
	arrow_left.z_index = 1
	graph_container.add_child(arrow_left)

	var arrow_right = Line2D.new()
	arrow_right.width = 2
	arrow_right.default_color = color.lightened(0.1)
	arrow_right.points = [pos, right]
	arrow_right.z_index = 1
	graph_container.add_child(arrow_right)

func _create_bidirectional_edge(u: int, v: int):
	var start_point = nodes_pos[u]
	var end_point = nodes_pos[v]
	var mid_point = (start_point + end_point) / 2
	
	var direction = (end_point - start_point).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var curve_offset = 20.0
	
	var control_point_uv = mid_point + perpendicular * curve_offset
	var curve_uv = _create_curved_line(start_point, end_point, control_point_uv, Color(0.75, 0.55, 0.35), u, v)
	
	var control_point_vu = mid_point - perpendicular * curve_offset
	var curve_vu = _create_curved_line(end_point, start_point, control_point_vu, Color(0.75, 0.55, 0.35), v, u)
	
	var lbl_node_uv = Control.new()
	lbl_node_uv.position = control_point_uv - Vector2(25, 5)
	lbl_node_uv.z_index = 20
	lbl_node_uv.custom_minimum_size = Vector2(50, 20)
	graph_container.add_child(lbl_node_uv)

	var lbl_uv = Label.new()
	lbl_uv.text = "0/%d (0)" % original_capacity[u][v]
	lbl_uv.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl_uv.add_theme_constant_override("outline_size", 2)
	lbl_uv.add_theme_font_size_override("font_size", 9)
	lbl_uv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_node_uv.add_child(lbl_uv)

	var lbl_node_vu = Control.new()
	lbl_node_vu.position = control_point_vu - Vector2(5, 25)
	lbl_node_vu.z_index = 20
	lbl_node_vu.custom_minimum_size = Vector2(50, 20)
	graph_container.add_child(lbl_node_vu)

	var lbl_vu = Label.new()
	lbl_vu.text = "0/%d (0)" % original_capacity[v][u]
	lbl_vu.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl_vu.add_theme_constant_override("outline_size", 2)
	lbl_vu.add_theme_font_size_override("font_size", 9)
	lbl_vu.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_node_vu.add_child(lbl_vu)

	edge_nodes.append({
		"from": u,
		"to": v,
		"cap": original_capacity[u][v],
		"line": curve_uv,
		"label_node": lbl_node_uv,
		"label": lbl_uv,
		"bidirectional": true,
		"color_base": Color(0.75, 0.55, 0.35)
	})
	
	edge_nodes.append({
		"from": v,
		"to": u,
		"cap": original_capacity[v][u],
		"line": curve_vu,
		"label_node": lbl_node_vu,
		"label": lbl_vu,
		"bidirectional": true,
		"color_base": Color(0.75, 0.55, 0.35)
	})

func _create_curved_line(start: Vector2, end: Vector2, control: Vector2, color: Color, from_node: int, to_node: int) -> Line2D:
	var line = Line2D.new()
	line.width = 2
	line.default_color = color
	line.z_index = 1
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	var dir_start = (control - start).normalized()
	var dir_end = (end - control).normalized()
	var adjusted_start = start + dir_start * 22
	var adjusted_end = end - dir_end * 22
	
	var curve_points = []
	var segments = 25
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var point = _quadratic_bezier(adjusted_start, control, adjusted_end, t)
		curve_points.append(point)
	
	line.points = curve_points
	graph_container.add_child(line)
	
	var arrow_point = curve_points[curve_points.size() - 1]
	var prev_point = curve_points[max(0, curve_points.size() - 3)]
	var arrow_dir = (arrow_point - prev_point).normalized()
	_draw_enhanced_arrow(arrow_point, arrow_dir, color)
	
	return line

func _draw_enhanced_arrow(pos: Vector2, dir: Vector2, color: Color):
	var arrow_size = 12.0
	var arrow_width = 8.0
	
	var left = pos - dir.rotated(deg_to_rad(30)) * arrow_size
	var right = pos - dir.rotated(deg_to_rad(-30)) * arrow_size
	
	var polygon = Polygon2D.new()
	polygon.polygon = [pos, left, right]
	polygon.color = color
	polygon.z_index = 2
	graph_container.add_child(polygon)

func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	return q0.lerp(q1, t)

func _get_arrow_points(from: Vector2, to: Vector2, node_radius: float = 20.0) -> Array:
	var dir = (to - from).normalized()
	var start_point = from + dir * node_radius
	var end_point = to - dir * node_radius
	return [start_point, end_point]

# JUGADOR
func _on_node_button_pressed(index: int, circle: ColorRect):
	if not game_started or game_over:
		return
	
	if selecting_source:
		source = index
		circle.color = Color(0.2, 0.8, 0.3)
		selecting_source = false
		_update_instructions("Ahora selecciona el nodo de DESTINO")
		_update_path_display()
		return
	
	if sink == -1:
		if index == source:
			_update_instructions("El destino no puede ser el mismo que el inicio")
			return
		sink = index
		circle.color = Color(0.8, 0.2, 0.3)
		_calculate_target_flow()
		_update_instructions("Configuración lista. Haz clic en el nodo inicio para empezar tu ruta")
		_update_path_display()
		return
	
	if current_path.is_empty():
		if index == source:
			current_path.append(index)
			circle.color = Color(0.3, 1.0, 0.4)
			_update_path_display()
			_update_instructions("Selecciona el siguiente nodo conectado")
	else:
		var last_node = current_path[-1]
		
		if capacity[last_node][index] > 0:
			var available = residual_graph[last_node][index]
			if available > 0:
				current_path.append(index)
				
				var node_control = graph_container.get_node_or_null("Node_" + str(index))
				if node_control:
					var node_circle = node_control.get_node_or_null("Circle")
					if node_circle and index != source and index != sink:
						node_circle.color = Color(0.3, 1.0, 0.4)
				
				_highlight_path()
				_update_path_display()
				
				if index == sink:
					_update_instructions("¡Ruta completa! Presiona [Enviar Flujo]")
					send_button.disabled = false
				else:
					_update_instructions("Continúa construyendo la ruta hasta el nodo")
			else:
				_update_instructions("Esta conexión está saturada (residual: 0/%d)" % capacity[last_node][index])
		else:
			_update_instructions("No hay conexión desde el nodo %d al nodo %d" % [last_node, index])

func _on_send_flow_pressed():
	if current_path.is_empty() or current_path[-1] != sink:
		_update_instructions("Debes construir una ruta completa hasta el destino")
		return

	var path_flow = INF
	for i in range(current_path.size() - 1):
		var u = current_path[i]
		var v = current_path[i + 1]
		var available = residual_graph[u][v]
		path_flow = min(path_flow, available)

	if path_flow <= 0:
		_update_instructions("Esta ruta ya no tiene capacidad disponible")
		return

	for i in range(current_path.size() - 1):
		var u = current_path[i]
		var v = current_path[i + 1]
		residual_graph[u][v] -= path_flow
		residual_graph[v][u] += path_flow
		flow_network[u][v] += path_flow

	await _animate_flow_sending(current_path, path_flow)

	total_flow_sent += path_flow
	packets_sent += 1
	
	_update_stats()
	_update_edge_visuals()
	_on_clear_path_pressed()

	if !_existe_camino_disponible():
		if total_flow_sent >= target_flow:
			_game_over(true)
		else:
			_update_instructions("No hay más caminos disponibles. Flujo: %d/%d" % [total_flow_sent, target_flow])
			await get_tree().create_timer(2.0).timeout
			_game_over(false)
	else:
		_update_instructions("Flujo enviado: %d unidades (Total: %d/%d). ¡Busca otro camino!" % [path_flow, total_flow_sent, target_flow])

func _on_clear_path_pressed():
	current_path.clear()
	selected_node = -1
	send_button.disabled = true
	_redraw_all_nodes()
	_update_path_display()
	if source != -1 and sink != -1:
		_update_instructions("Selecciona el nodo de inicio")
	else:
		_update_instructions("Selecciona nodos de inicio y destino")

# VISUAL
func _highlight_path():
	for i in range(current_path.size() - 1):
		var u = current_path[i]
		var v = current_path[i + 1]
		for e in edge_nodes:
			if e.from == u and e.to == v:
				e.line.default_color = Color(0.3, 1.0, 0.5)
				e.line.width = 6

func _update_edge_visuals():
	for e in edge_nodes:
		var u = e.from
		var v = e.to
		var cap = original_capacity[u][v]
		var used = flow_network[u][v]
		var residual = residual_graph[u][v]
		
		if cap <= 0:
			continue
		
		var ratio = float(used) / float(cap)

		var new_color
		if ratio == 0:
			new_color = e.color_base if e.has("color_base") else Color(0.75, 0.55, 0.35)
		elif ratio < 0.5:
			new_color = Color(0.2, 0.9, 0.3)
		elif ratio < 0.8:
			new_color = Color(1.0, 0.9, 0.2)
		elif ratio < 1.0:
			new_color = Color(1.0, 0.5, 0.0)
		else:
			new_color = Color(1.0, 0.2, 0.2)
		
		e.line.default_color = new_color
		e.line.width = 2 + (ratio * 2)

		if e.has("bidirectional") and e.bidirectional:
			if u < v:
				e.label.text = "%d/%d (%d)" % [used, cap, residual]
			else:
				e.label.text = "%d/%d (%d)" % [used, cap, residual]
			e.label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			e.label.text = "%d/%d (%d)" % [used, cap, residual]
			e.label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

func _redraw_all_nodes():
	for i in range(V):
		var node_control = graph_container.get_node_or_null("Node_" + str(i))
		if node_control:
			var circle = node_control.get_node_or_null("Circle")
			if circle:
				if i == source:
					circle.color = Color(0.2, 0.9, 0.3)
				elif i == sink:
					circle.color = Color(0.9, 0.2, 0.3)
				else:
					circle.color = Color(0.15, 0.25, 0.45)
	
	_update_edge_visuals()

func _calculate_target_flow():
	var temp_residual = []
	for i in range(V):
		var row = []
		for j in range(V):
			row.append(original_capacity[i][j])
		temp_residual.append(row)
	
	target_flow = 0
	while true:
		var path = _bfs_find_path_temp(temp_residual)
		if path.is_empty():
			break
		
		var path_flow = INF
		for i in range(path.size() - 1):
			var u = path[i]
			var v = path[i + 1]
			path_flow = min(path_flow, temp_residual[u][v])
		
		for i in range(path.size() - 1):
			var u = path[i]
			var v = path[i + 1]
			temp_residual[u][v] -= path_flow
			temp_residual[v][u] += path_flow
		
		target_flow += path_flow
	
	stats_label.text = "Flujo: 0/%d | Paquetes: 0" % target_flow

func _bfs_find_path_temp(res) -> Array:
	var parent = []
	parent.resize(V)
	for i in range(V):
		parent[i] = -1
	var visited = []
	visited.resize(V)
	for i in range(V):
		visited[i] = false

	var queue = [source]
	visited[source] = true
	while queue.size() > 0:
		var u = queue.pop_front()
		for v in range(V):
			if !visited[v] and res[u][v] > 0:
				parent[v] = u
				visited[v] = true
				queue.append(v)
	
	if !visited[sink]:
		return []
	
	var path = []
	var v = sink
	while v != source:
		path.insert(0, v)
		v = parent[v]
	path.insert(0, source)
	return path

func _animate_flow_sending(path: Array, flow_value: int):
	for i in range(path.size() - 1):
		var u = path[i]
		var v = path[i + 1]
		var start_pos = nodes_pos[u]
		var end_pos = nodes_pos[v]
		
		var edge_line = null
		for e in edge_nodes:
			if e.from == u and e.to == v:
				edge_line = e.line
				break
		
		for j in range(3):
			await _spawn_particle_along_path(edge_line if edge_line else null, start_pos, end_pos)
			await get_tree().create_timer(0.1).timeout

func _spawn_particle_along_path(line: Line2D, start: Vector2, end: Vector2):
	var particle = ColorRect.new()
	particle.custom_minimum_size = Vector2(8, 8)
	particle.z_index = 15
	
	var shader_code = """
shader_type canvas_item;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	
	if (dist > 0.5) {
		COLOR.a = 0.0;
	} else {
		COLOR = vec4(0.4, 1.0, 1.0, 1.0);
		float glow = 1.0 - (dist * 2.0);
		COLOR.rgb += vec3(glow * 0.5);
		COLOR.a = smoothstep(0.5, 0.3, dist);
	}
}
"""
	
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	particle.material = material
	
	if line and line.points.size() > 1:
		particle.position = line.points[0] - Vector2(4, 4)
	else:
		particle.position = start - Vector2(4, 4)
	
	graph_container.add_child(particle)
	
	var tween = get_tree().create_tween()
	
	if line and line.points.size() > 1:
		# Seguir la curva punto por punto
		for i in range(1, line.points.size()):
			var target = line.points[i] - Vector2(4, 4)
			var duration = 0.4 / float(line.points.size())
			tween.tween_property(particle, "position", target, duration)
	else:
		# Línea recta simple
		tween.tween_property(particle, "position", end - Vector2(4, 4), 0.4)
	
	# Efecto de fade out 
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3).set_delay(0.1)
	
	await tween.finished
	particle.queue_free()

# Ataque
func _nemesis_attack():
	if nemesis_active:
		return
	
	nemesis_active = true
	nemesis_attacks += 1
	
	var available_edges = []
	for e in edge_nodes:
		if residual_graph[e.from][e.to] > 0:
			available_edges.append(e)
	
	if available_edges.is_empty():
		nemesis_active = false
		return
	
	var random_edge = available_edges[randi() % available_edges.size()]
	var u = random_edge.from
	var v = random_edge.to
	
	var blocked_amount = min(5, residual_graph[u][v])
	residual_graph[u][v] -= blocked_amount
	
	random_edge.line.default_color = Color(1.0, 0.0, 0.0)
	random_edge.line.width = 3
	_update_instructions("¡ATAQUE NEMESIS! Conexión %d→%d bloqueada temporalmente (--%d)" % [u, v, blocked_amount])
	
	_spawn_attack_effect(nodes_pos[u], nodes_pos[v])
	
	await get_tree().create_timer(5.0).timeout
	
	residual_graph[u][v] += blocked_amount
	_update_edge_visuals()
	_update_instructions("Conexión %d→%d restaurada. ¡Continúa!" % [u, v])
	
	nemesis_active = false

func _spawn_attack_effect(start: Vector2, end: Vector2):
	for i in range(5):
		var particle = ColorRect.new()
		particle.color = Color(1.0, 0.0, 0.0, 0.8)
		particle.custom_minimum_size = Vector2(8, 8)
		particle.position = start.lerp(end, randf())
		particle.z_index = 20
		graph_container.add_child(particle)
		
		var tween = get_tree().create_tween()
		tween.tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.parallel().tween_property(particle, "scale", Vector2(3, 3), 1.0)
		await tween.finished
		particle.queue_free()

func _game_over(victory: bool):
	game_over = true
	game_started = false
	
	if victory:
		_update_instructions("Flujo máximo alcanzado: %d/%d unidades" % [total_flow_sent, target_flow])
		await get_tree().create_timer(3.0).timeout
		ControlGame.avanzarNivel()
		get_tree().change_scene_to_file("res://niveles.tscn")
	else:
		_update_instructions("Tiempo agotado. Flujo logrado: %d/%d" % [total_flow_sent, target_flow])

func _on_start_pressed():
	game_started = true
	game_over = false
	time_remaining = 300.0
	total_flow_sent = 0
	packets_sent = 0
	nemesis_attacks = 0
	nemesis_active = false
	current_path.clear()
	selected_node = -1
	_initialize_flow_network()
	await _draw_fixed_graph()
	_update_instructions("¡Haz clic en el nodo de inicio para iniciar tu ruta!")
	_update_stats()
	start_button.disabled = true
	send_button.disabled = true
	timer_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

# UI UPDATES
func _update_instructions(text: String):
	instructions.text = text

func _update_stats():
	var percentage = (float(total_flow_sent) / float(target_flow)) * 100
	stats_label.text = "Flujo: %d/%d (%.0f%%)
Paq: %d | Ataques: %d" % [
		total_flow_sent, target_flow, percentage, packets_sent, nemesis_attacks
	]

func _update_path_display():
	if current_path.is_empty():
		path_info.text = "Ruta actual: Ninguna"
	else:
		var path_str = ""
		for i in range(current_path.size()):
			path_str += str(current_path[i])
			if i < current_path.size() - 1:
				path_str += " → "
		path_info.text = "Ruta actual: " + path_str

# VERIFICACIÓN DE CAMINOS
func _existe_camino_disponible() -> bool:
	var visited = []
	visited.resize(V)
	for i in range(V):
		visited[i] = false
	
	var queue = [source]
	visited[source] = true
	
	while queue.size() > 0:
		var u = queue.pop_front()
		for v in range(V):
			if !visited[v] and residual_graph[u][v] > 0:
				if v == sink:
					return true
				visited[v] = true
				queue.append(v)
	
	return false
# aYUDA
func _on_boton_ayuda_pressed() -> void:
	panel_ayuda.visible = true
	start_button.visible = false
	send_button.visible = false
	clear_button.visible = false

func _on_boton_continuar_pressed() -> void:
	panel_ayuda.visible = false
	start_button.visible = true
	send_button.visible = true
	clear_button.visible = true




func _on_boton_continuar_2_pressed() -> void:
	panelCiber.visible=false
	_iniciar_mision()
