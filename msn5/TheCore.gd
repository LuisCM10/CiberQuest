extends Control

# -----Constantes----- 
const LINEA_DE_CONEXION_NODOS = "conexion"
const LINEA_DE_RECORRIDO_NODOS = "recorrido"
#const LINEA_DE_CONEXION_PESOS_NODOS = "Pesos"
const LINEA_DE_DIJKSTRA_NODOS = "dijkstra"
const LINEA_DE_RECONSTRUCCION_NODOS = "reconstruccion"
#const LINEA_DE_CONEXION_CAPACIDAD_NODOS = "Capacidad"
const LINEA_DE_FLUJO_NODOS = "flujo"
const LINEA_DE_FLUJO_MAX_NODOS = "flujoMaximo"
const MAX_WRONG_CLICKS = 5
# Variable visuales
@onready var PanelGrafo = $PanGrafo
@onready var lblIntro =$VBoxContainer/LblIntruccion
@onready var lblTime = $VBoxContainer/LblTime
@onready var lblRecorrido = $VBoxContainer/lblRecorrido
@onready var lblFlujo = $VBoxContainer/LblFlujo
@onready var BtnIniciar = $VBoxContainer/BtnIniciar
@onready var BtnEnviar = $VBoxContainer/BtnEnviar
@onready var BtnLimpiar = $VBoxContainer/BtnLimpiar
@onready var view = get_viewport_rect().size * 0.3
#----------Ayuda----------
@onready var boton_ayuda = $BotonAyuda
@onready var panel_ayuda = $PanelAyuda
@onready var panelCiber = $PanelCiber
@onready var lExplicaCiber = $PanelCiber/ExplicaCiber
@onready var boton_continuar2 = $PanelCiber/BotonContinuar2
@onready var label_explicacion = $PanelAyuda/LabelExplicacion
@onready var boton_continuar = $PanelAyuda/BotonContinuar
#transicion
@onready var fade_transition = $CanvasLayer  

var grafo = Grafo.new()

# Variables control
var bfs = true
var dijstra = false
var kruskal = false
var flujo = false
var start = false
var time_remaining := 120.0

var num_vertices = 8
var prob_conexion = 0.35
var lineasConexion = []
var lineasVisuales = []
var labels = []

var vertActual = null
var aristaActual = null
var origin
var destino

var UserRecorrido = []
var recorrido = []
var KruskalLineas = []
var parent = []
var wrong_clicks = 8
var original_capacity = []
var flow_network = []
var residual_graph = []
var target_flow
var total_flow_sent := 0
var packets_sent := 0
var current_path = []
var pesoTotal = 0

func _ready() -> void:
	grafo = Grafo.new()
	fade_transition.visible = false
	panelCiber.visible = true
	panel_ayuda.visible = false
	
	iniciarMatrices()	
	
	for i in range(num_vertices):
		var angle = (2 * PI * (i+num_vertices - 1)) / 10
		var x = 150 + view[0] * cos(angle)
		var y = 90 + view[1] * sin(angle)
		var positions = Vector2(x, y)
		var vertice = Nodo.new(i, positions)
		grafo.add_vertice(vertice)
	
	# Conectar vértices...
	for i in range(num_vertices):
		var vertic1 = grafo.searchVertice(i)
		for j in range(num_vertices):
			if i != j:
				if randf() < prob_conexion:
					var vertic2 = grafo.searchVertice(j)
					grafo.connect_vertice(vertic1, vertic2, 1, 1)
	dibujarGrafo()

func iniciarMatrices():
	grafo.matriz_adya = []
	grafo.matriz_adya.resize(num_vertices)
	grafo.matriz_capa_max = []
	grafo.matriz_capa_max.resize(num_vertices)
	grafo.matriz_peso = []
	grafo.matriz_peso.resize(num_vertices)
	grafo.matriz_capa_usa = []
	grafo.matriz_capa_usa.resize(num_vertices)
	for i in range(num_vertices):
		grafo.matriz_adya[i] = []
		grafo.matriz_adya[i].resize(num_vertices)
		grafo.matriz_capa_max[i] = []
		grafo.matriz_capa_max[i].resize(num_vertices)
		grafo.matriz_peso[i] = []
		grafo.matriz_peso[i].resize(num_vertices)
		grafo.matriz_capa_usa[i] = []
		grafo.matriz_capa_usa[i].resize(num_vertices)
		for j in range(num_vertices):
			grafo.matriz_adya[i][j] = 0
			grafo.matriz_capa_max[i][j] = 0
			grafo.matriz_peso[i][j] = 0
			grafo.matriz_capa_usa[i][j] = 0
			
func _process(delta: float) -> void:
	if start:
		time_remaining -= delta
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		lblTime.text = "Tiempo: %02d:%02d" % [minutes, seconds]
		
		if time_remaining < 30:
			lblTime.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		
		if time_remaining <= 0:
			lblIntro.text = "Haz demorado mucho, intentalo de nuevo"
			BtnIniciar.visible = true
			start = false
			time_remaining = 120
	pass
	
func dibujarGrafo():
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]
		var button = Button.new()
		button.name = str(vertice.id) + "Button"
		button.text = str(vertice.id)
		button.size = Vector2(32, 32)
		button.add_theme_color_override("style_normal", Color(255,255,255,1))
		button.add_theme_color_override("icon_pressed_color", Color(0.349, 0.387, 0.459, 1.0))
		button.add_theme_color_override("icon_hover_color", Color(182.389, 182.389, 182.389, 1.0))
		button.position = vertice.posicion
		button.flat = true
		button.connect("pressed", Callable(self, "_on_nodo_clicked").bind(vertice))
		PanelGrafo.add_child(button)
		# Dibujar conexiones (líneas)
		for ady in vertice.adyacentes:
			var indice_ady = grafo.vertices.find(ady)
			if indice_ady > i:
				dibujarLineas(vertice, ady, LINEA_DE_CONEXION_NODOS, false)
	pass
	
func dibujarLineas(origen, destin, funcion,lab = true, correcto = true, tipo = "NoDirigida"):
	var arista = Arista.new(origen, destin)	
	
	match funcion:
		LINEA_DE_CONEXION_NODOS:
			arista.tipo = tipo
			lineasConexion.append(arista)
			
		LINEA_DE_DIJKSTRA_NODOS:
			arista.funcion = funcion
			arista.color = Color(0.906, 0.686, 0.0, 1.0)
			lineasVisuales.append(arista)
		LINEA_DE_FLUJO_MAX_NODOS:
			arista.funcion = funcion
			arista.color = Color(0.833, 0.066, 0.064, 1.0)
			lineasVisuales.append(arista)
		LINEA_DE_FLUJO_NODOS:
			arista.funcion = funcion
			arista.color = Color(0.0, 0.541, 0.448, 1.0)
			if not correcto:
				arista.color = Color(1.0, 0.0, 0.102, 1.0)
			lineasVisuales.append(arista)
		LINEA_DE_RECONSTRUCCION_NODOS:
			arista.funcion = funcion
			arista.color = Color(0.488, 0.504, 0.378, 1.0)
			if not correcto:
				arista.color = Color(1.0, 0.0, 0.102, 1.0)
			lineasVisuales.append(arista)
		LINEA_DE_RECORRIDO_NODOS:
			arista.duracion = 0.6			
			if correcto:
				arista.color = Color(0.185, 0.416, 1.0, 1.0)
				if destin.is_origin:
					arista.color = Color(53.064, 244.585, 0.0, 1.0)
			else:
				arista.color = Color(1.0, 0.0, 0.102, 1.0)
			lineasVisuales.append(arista)			
	PanelGrafo.add_child(arista)
	if lab and funcion == LINEA_DE_CONEXION_NODOS: 
		var start_point = arista.line.points[0] 
		var end_point = arista.end_point
		var mid_point = (start_point + end_point) / 2
		var direction = (end_point - start_point).normalized()
		var perpendicular = Vector2(-direction.y, direction.x)
		var curve_offset = 9
		var control_point_uv = mid_point + perpendicular * curve_offset
		var label = Label.new()
		label.position = control_point_uv - Vector2(25, 5)
		label.z_index = 20
		label.custom_minimum_size = Vector2(50, 30)
		label.text =  "%d" % grafo.matriz_peso[origen.id][destin.id]
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_font_size_override("font_size", 10)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER		
		# Nombre único
		if not has_node("Label," + str(origen.id) + "," + str(destin.id)):
			label.name = "Label," + str(origen.id) + "," + str(destin.id)
		else:
			label.name = "Label," + str(destin.id) + "," + str(origen.id)		
		PanelGrafo.add_child(label)
		labels.append(label)
		label.visible = true

func dibujarConexionKruskal():
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]		
		for ady in vertice.adyacentes:
			var edge_scene = preload("res://edge_line.tscn").instantiate()
			edge_scene.connect_nodes(vertice, ady, grafo.getPeso(vertice, ady))
			edge_scene.connect("edge_selected", Callable(self, "_on_edge_selected"))
			edge_scene.update_scale(1.0)
			PanelGrafo.add_child(edge_scene)
			lineasConexion.append(edge_scene)

	parent.resize(num_vertices)
	for i in range(num_vertices):
		parent[i] = i
		
func limpiarVisual():
	for x in lineasVisuales:
		x.queue_free()
	lineasVisuales.clear()
	time_remaining = 120
	
func limpiarConexiones():
	for x in lineasConexion:
		x.queue_free()
	lineasConexion.clear()
	time_remaining = 120
	
func dibujarGrafoNuevo():
	for i in range(num_vertices):
		var vertic1 = grafo.searchVertice(i)
		for j in range(num_vertices):
			if i != j:
				if randf() < (prob_conexion - 0.25):
					var vertic2 = grafo.searchVertice(j)
					var peso = randi_range(1, 15)
					var capacidad = randi_range(1, 20)
					grafo.connect_vertice(vertic1, vertic2, peso, capacidad, "dirigido")
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]		
		for ady in vertice.adyacentes:
			var indice_ady = grafo.vertices.find(ady)
			if indice_ady != i:
				dibujarLineas(vertice, ady, LINEA_DE_CONEXION_NODOS, true, true, "Dirigido")
				
func dibujarConexiones():
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]
		for ady in vertice.adyacentes:
			var indice_ady = grafo.vertices.find(ady)
			if indice_ady != i:
				dibujarLineas(vertice, ady, LINEA_DE_CONEXION_NODOS)
	
func mostrarPesos(opc : bool):
	for x in labels:
			x.visible = opc

func mostrarCapacidad(opc:bool):
	for x in labels:
		var nam = str(x.name)
		nam = nam.split(",")
		if nam.size() > 2:
			print(nam[1])
			print(nam[2])
			x.text = str(grafo.getFlujoUsado(grafo.searchVertice(int(nam[1])), grafo.searchVertice(int(nam[2]))))+"/"+str(grafo.getFlujoMax(grafo.searchVertice(int(nam[1])), grafo.searchVertice(int(nam[2]))))
			x.visible = opc
		
func _on_edge_selected(edge):
	print("Se selecciono una conexion")
	if start and kruskal:		
		kruskal_click(edge)
	
func _on_nodo_clicked(vertice):
	if start and dijstra:
		recorrido.append(vertActual)
	vertActual = vertice
	if start and bfs:
		if not UserRecorrido.has(vertActual):
			BFS()
			lblRecorrido.text = str(recorStr())
		else:
			lblIntro.text = "El nodo "+ str(vertActual.id) + " ya se encuentra en el recorrido"
	if start and dijstra:
		
		# Verificar si el nodo está conectado al actual (no permitir avanzar si no lo está)
		if grafo.matriz_adya[recorrido.get(recorrido.size()-1).id][vertActual.id] == 0:
			recorrido.pop_back()
			lblIntro.text = "El nodo "+ str(vertActual.id) + " no esta conectado con los nodos anteriores"
			return  # No hacer nada si no está conectado
		
		var idx = camino_optimo.find(recorrido.get(recorrido.size()-1).id)
		if idx == -1 or idx == camino_optimo.size() - 1:
			return
		
		var siguiente_correcto = camino_optimo[idx + 1]
		
		if vertActual.id == siguiente_correcto:
			pesoTotal += grafo.matriz_peso[recorrido.get(recorrido.size()-1).id][vertActual.id]
			dibujarLineas(recorrido.get(recorrido.size()-1), vertActual, LINEA_DE_DIJKSTRA_NODOS)
			UserRecorrido.append(vertActual)
			lblRecorrido.text = str(recorStr())
			lblIntro.text = "Peso total actual: " + str(pesoTotal)
			print("Recorrido paso por: "+ str(vertActual.id))
			if vertActual == destino:
				print("¡GANASTE!")
				esperando_click = false
				await get_tree().create_timer(2).timeout
				lblIntro.text = "Has hallado la ruta mas rapida al backup del sistema envia una señal para avanzar al siguiente paso."
				BtnEnviar.visible = true
				start = false
		else:
			dibujarLineas(recorrido.get(recorrido.size()-1), vertActual, LINEA_DE_DIJKSTRA_NODOS, false, false)
			await get_tree().create_timer(2).timeout
			lineasVisuales.pop_back().queue_free()
			recorrido.pop_back()
	if start and flujo:
		var index = vertActual
		if current_path.is_empty():
			if index == origin:
				current_path.append(index)
				_update_path_display()
				_update_instructions("Selecciona el siguiente nodo conectado")
		else:
			var last_node = current_path[-1]
			
			if grafo.matriz_capa_max[last_node.id][index.id] > 0:
				var available = residual_graph[last_node.id][index.id]
				if available > 0:
					current_path.append(index)
					dibujarLineas(last_node, index, LINEA_DE_FLUJO_NODOS, false)
					
					_highlight_path()
					_update_path_display()
					
					if index == destino:
						_update_instructions("¡Ruta completa! Presiona [Enviar Flujo]")
						BtnEnviar.disabled = false
					else:
						_update_instructions("Continúa construyendo la ruta hasta el nodo")
				else:
					_update_instructions("Esta conexión está saturada (residual: 0/%d)" % grafo.matriz_capa_max[last_node.id][index.id])
					dibujarLineas(last_node, index, LINEA_DE_FLUJO_MAX_NODOS, false, false)
			else:
				_update_instructions("No hay conexión desde el nodo %d al nodo %d" % [last_node.id, index.id])

func recorStr(tipo = "nodo") -> Array:
	var recor = []
	for x in UserRecorrido:
		if tipo == "nodo":
			recor.append(x.id)
		if tipo == "arista":
			recor.append(str(x.node_a.id)+ " → " +str(x.node_b.id))
	return recor
	
func _highlight_path():
	for i in range(current_path.size() - 1):
		var u = current_path[i]
		var v = current_path[i + 1]
		for e in lineasConexion:
			if e.origen == u and e.destino == v:
				dibujarLineas(u, v, LINEA_DE_FLUJO_NODOS, false, true)
	
#----------------- Kruskal ----------------------------
func kruskal_click(edge):
	var n1 = grafo.vertices.find(edge.node_a)
	var n2 = grafo.vertices.find(edge.node_b)

	if find(n1) != find(n2):
		union(n1, n2)
		KruskalLineas.append(edge)
		UserRecorrido.append(edge)
		lblRecorrido.text = str(recorStr("arista"))
		edge.set_correct(true)
	else:
		edge.set_correct(false)
		lblIntro.text = "Te has equivocado de conexion, intentalo de nuevo."
		await get_tree().create_timer(0.5).timeout
		edge.set_correct(false)

	if KruskalLineas.size() == num_vertices - 1:
		start = false
		lblIntro.text = "Has reconstruido el sistema es hora de enviar una nueva señal de victoria."
		BtnEnviar.visible = true
		pass

func find(i):
	if parent[i] != i:
		parent[i] = find(parent[i])
	return parent[i]

func union(a, b): #une nodos	
	var ra = find(a)
	var rb = find(b) #
	if ra != rb:
		parent[rb] = ra #conecta la raiz uno de otro

# -------------------- BFS ------------------------------------
func iniciarRecorridos():
	if not vertActual:
		lblIntro.text = "Necesitas elegir un nodo en el cual iniciar el recorrido."
		return
	var origin_index = randi() % grafo.vertices.size()
	origin = grafo.vertices[origin_index]
	while origin == vertActual or vertActual.adyacentes.has(origin):
		origin_index = randi() % grafo.vertices.size()
		origin = grafo.vertices[origin_index]
	origin.is_origin = true	
	destino = vertActual
	recorrido = grafo.bfs(vertActual)
	UserRecorrido.append(vertActual)
	lblRecorrido.text = str(recorStr())
	lblIntro.text = "Haz elegido iniciar la busqueda con el nodo "+str(vertActual.id)+"."
	start = true
	BtnIniciar.visible = false
	BtnEnviar.visible = false

func BFS () :	
	for x in UserRecorrido:
		if x.adyacentes.has(vertActual):
			UserRecorrido.append(vertActual)
			var verificar = recorrido[UserRecorrido.size()-1] == vertActual
			if not verificar:
				dibujarLineas(x,vertActual,LINEA_DE_RECORRIDO_NODOS, false, false)
				UserRecorrido.remove_at(UserRecorrido.size()-1)
				await get_tree().create_timer(3).timeout
				return
			dibujarLineas(x,vertActual,LINEA_DE_RECORRIDO_NODOS, false)
			if verificar and vertActual == origin:
				lblIntro.text = "Has hallado el backup del sistema es necesario enviar una señal de victoria."
				BtnLimpiar.visible = false
				BtnEnviar.visible = true
				start = false
			await get_tree().create_timer(3).timeout
			return
			
#--------------------------------- Flujo ------------------------------------------------------------
func _initialize_flow_network():
	# Guardar capacidades originales
	original_capacity.clear()
	for i in range(num_vertices):
		var row = []
		for j in range(num_vertices):
			row.append(grafo.matriz_capa_max[i][j])
		original_capacity.append(row)
	
	# Inicializar flujo en 0
	flow_network.clear()
	for i in range(num_vertices):
		var row = []
		for j in range(num_vertices):
			row.append(0)
		flow_network.append(row)
	
	# Inicializar grafo residual = capacidad original(matrices)
	residual_graph.clear()
	for i in range(num_vertices):
		var row = []
		for j in range(num_vertices):
			row.append(grafo.matriz_capa_max[i][j])
		residual_graph.append(row)

func _calculate_target_flow():
	var temp_residual = []
	for i in range(num_vertices):
		var row = []
		for j in range(num_vertices):
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
	
	lblIntro.text = "Flujo: 0/%d | Paquetes: 0" % target_flow
##BFS

func _bfs_find_path_temp(res) -> Array:
	var parente = []
	parente.resize(num_vertices)
	for i in range(num_vertices):
		parente[i] = -1
	var visited = []
	visited.resize(num_vertices)
	for i in range(num_vertices):
		visited[i] = false

	var queue = [origin.id]
	visited[origin.id] = true
	while queue.size() > 0:
		var u = queue.pop_front()
		for v in range(num_vertices):
			if !visited[v] and res[u][v] > 0:
				parente[v] = u
				visited[v] = true
				queue.append(v)
	
	if !visited[destino.id]:
		return []
	
	var path = []
	var v = destino.id
	while v != origin.id:
		path.insert(0, v)
		v = parente[v]
	path.insert(0, origin.id)
	return path

func _animate_flow_sending(path: Array, flow_value: int):
	for i in range(path.size() - 1):
		var u = path[i]
		var v = path[i + 1]
		var start_pos = grafo.vertices[u]
		var end_pos = grafo.vertices[v]
		
		var edge_line = null
		for e in lineasVisuales:
			if e.origen == u and e.destino == v:
				edge_line = e.linea
				break
		
		for j in range(3):
			await _spawn_particle_along_path(edge_line if edge_line else null, start_pos, end_pos)
			await get_tree().create_timer(0.1).timeout

func _spawn_particle_along_path(line: Line2D, starte: Vector2, end: Vector2):
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
	#CUADRADO VIajando
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	particle.material = material
	
	if line and line.points.size() > 1:
		particle.position = line.points[0] - Vector2(4, 4)
	else:
		particle.position = starte - Vector2(4, 4)
	
	PanelGrafo.add_child(particle)
	
	var tween = get_tree().create_tween()
	
	if line and line.points.size() > 1:
		# Seguir la curva punto por punto
		for i in range(1, line.points.size()):
			var target = line.points[i] - Vector2(4, 4)
			var duration = 0.4 / float(line.points.size())
			tween.tween_property(particle, "position", target, duration)
	else:
		# LÃ­nea recta simple
		tween.tween_property(particle, "position", end - Vector2(4, 4), 0.4)
	
	# Efecto de fade out 
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.3).set_delay(0.1)
	
	await tween.finished
	particle.queue_free()
	
func enviarFlujo():
	if current_path.is_empty() or current_path[-1] != destino:
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
	_on_btn_limpiar_pressed()

	if !_existe_camino_disponible():
		if total_flow_sent >= target_flow:
			_game_over(true)
		else:
			_update_instructions("No hay más caminos disponibles. Flujo: %d/%d" % [total_flow_sent, target_flow])
			await get_tree().create_timer(2.0).timeout
			_game_over(false)
	else:
		_update_instructions("Flujo enviado: %d unidades (Total: %d/%d). ¡Busca otro camino!" % [path_flow, total_flow_sent, target_flow])

func _update_instructions(text: String):
	lblFlujo.text = text
	
func _update_stats():
	var percentage = (float(total_flow_sent) / float(target_flow)) * 100
	lblIntro.text = "Flujo: %d/%d (%.0f%%) 
Paq: %d" % [
		total_flow_sent, target_flow, percentage, packets_sent
	]
	
func _update_path_display():
	if current_path.is_empty():
		lblRecorrido.text = "Ruta actual: Ninguna"
	else:
		var path_str = ""
		for i in range(current_path.size()):
			path_str += str(current_path[i])
			if i < current_path.size() - 1:
				path_str += " → "
		lblRecorrido.text = "Ruta actual: " + path_str
		
func _update_edge_visuals():
	for e in lineasVisuales:
		var u = e.origen
		var v = e.destino
		var cap = original_capacity[u.id][v.id]
		var used = flow_network[u.id][v.id]
		var residual = residual_graph[u.id][v.id]
		
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
		
		e.linea.default_color = new_color
		e.linea.width = 2 + (ratio * 2)

		if e.has("bidirectional") and e.bidirectional:
			if u.id < v.id:
				e.label.text = "%d/%d (%d)" % [used, cap, residual]
			else:
				e.label.text = "%d/%d (%d)" % [used, cap, residual]
			e.label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			e.label.text = "%d/%d (%d)" % [used, cap, residual]
			e.label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			
func _existe_camino_disponible() -> bool:
	var visited = []
	visited.resize(num_vertices)
	for i in range(num_vertices):
		visited[i] = false
	
	var queue = [origin.id]
	visited[origin.id] = true
	
	while queue.size() > 0:
		var u = queue.pop_front()
		for v in range(num_vertices):
			if !visited[v] and residual_graph[u][v] > 0:
				if v == destino.id:
					return true
				visited[v] = true
				queue.append(v)
	
	return false
	
func _game_over(victory: bool):
	start = false
	
	if victory:
		_update_instructions("Flujo máximo alcanzado: %d/%d unidades" % [total_flow_sent, target_flow])
		await get_tree().create_timer(3.0).timeout
		BtnEnviar.disabled = false
	else:
		_update_instructions("Tiempo agotado. Flujo logrado: %d/%d" % [total_flow_sent, target_flow])
		_on_btn_limpiar_pressed()


# -------------------------------- Dijsktra --------------------------------------------------------

var camino_optimo = []   
var esperando_click = false
#var adj_matrix = grafo.matriz_adya

func dijkstra(started):
	var dist = []
	var prev = []
	var visited = []
	
	for i in range(num_vertices):
		dist.append(999999 if i != started else 0)
		prev.append(-1)
		visited.append(false)
	
	for iteration in range(num_vertices):
		var u = -1
		var min_dist = 999999
		for i in range(num_vertices):
			if not visited[i] and dist[i] < min_dist:
				min_dist = dist[i]
				u = i
		
		if u == -1:
			break
		
		visited[u] = true
		
		for v in range(num_vertices):
			if grafo.matriz_adya[u][v] > 0 and not visited[v]:
				var alt = dist[u] + grafo.matriz_peso[u][v]
				if alt < dist[v]:
					dist[v] = alt
					prev[v] = u
	
	return {"dist": dist, "prev": prev}
	
# ────────────────────────────────────────────────
# CALCULAR EL CAMINO ÓPTIMO CON DIJKSTRA
# ────────────────────────────────────────────────
func _calcular_camino_optimo():
	var result = dijkstra(origin.id)
	var dist = result["dist"]
	var prev = result["prev"]
		
	camino_optimo = _reconstruir_camino(prev, destino.id)

func _reconstruir_camino(prev, destin):
	var camino = []
	var actual = destin
	while actual != -1:
		camino.append(actual)
		actual = prev[actual]
	camino.reverse()
	if camino.size() == 0 or camino[0] != origin.id:
		camino = []
	return camino

#------------------------- Controles juego ----------------------------------------------------------
func _on_btn_iniciar_pressed() -> void:
	if bfs:
		iniciarRecorridos()		
	if dijstra:
		_calcular_camino_optimo()
		start = true
		UserRecorrido.append(origin)
		recorrido.clear()
		recorrido.append(origin)
		lblRecorrido.text = str(recorStr())
		lblIntro.text = "Intenta hallar la ruta mas corta hacia el nodo de destino ("+ str(destino.id)+"), desde el nodo fuente ("+ str(origin.id)+")."
		BtnIniciar.visible = false
		BtnEnviar.visible = false
		BtnLimpiar.visible = true
	if kruskal:
		lblIntro.text = "Intenta construir una red conextada mas rapida y segura, mucha suerte."
		start = true
		BtnIniciar.visible = false
		BtnEnviar.visible = false
	if flujo:
		start = true		
		_initialize_flow_network()
		_calculate_target_flow()
		BtnIniciar.visible = false
		BtnEnviar.visible = true
		BtnEnviar.disabled = true
		
	pass # Replace with function body.


func _on_btn_enviar_pressed() -> void:
	if bfs:
		print(recorrido)
		print(UserRecorrido)
		if UserRecorrido.has(origin):
			lblIntro.text = "Felicidades, restauraste las conexiones entre servidores. Ahora es hora de hallar nuestro camino mas corto hasta el nodo "+str(origin.id)+" para hallar el backup del sistema."
			bfs = false
			destino = origin
			origin = UserRecorrido[0]
			UserRecorrido.clear()
			lblRecorrido.text = str(recorStr())
			recorrido.clear()
			dijstra = true
			limpiarVisual()
			limpiarConexiones()
			dibujarGrafoNuevo()
			BtnIniciar.visible = true
			BtnEnviar.visible = false
			BtnLimpiar.visible = false
			start = false			
			return
		else:
			lblIntro.text = "Parece que aun te falta algun nodo por recorrer. Sera necesario revisar."
			return
	if dijstra:
		UserRecorrido.clear()
		recorrido.clear()
		lblRecorrido.text = str(recorStr())
		lblIntro.text = "Felicidades, hallaste el camino y enviaste el backup. Ahora es hora de construir un sistema seguro y liviano hasta cada uno de nuestros servidores."
		dijstra = false
		BtnIniciar.visible = true
		BtnEnviar.visible = false
		BtnLimpiar.visible = false
		limpiarVisual()
		# Logica para pasar al nivel kruskal		
		limpiarConexiones()
		mostrarPesos(false)
		dibujarConexionKruskal()
		kruskal = true
		return
	if kruskal:
		lblIntro.text = "Felicidades, construiste una red segura. Ahora es necesario verificar que las conexiones sean seguras y eficientes entre nuestros servidores, hora de hacer un pentesting."
		kruskal = false
		UserRecorrido.clear()
		recorrido.clear()
		limpiarVisual()
		limpiarConexiones()
		dibujarConexiones()
		mostrarCapacidad(true)
		BtnIniciar.visible = true
		BtnEnviar.visible = false
		BtnLimpiar.visible = false
		flujo = true
		return
	if flujo:
		if start:
			enviarFlujo()
			BtnEnviar.disabled = true
			BtnLimpiar.visible = false
			return
		else:
			lblIntro.text = "Felicidades, completaste todas las tareas. Has hecho un gran trabajo el dia de hoy, es hora de descansa. Pero recuerda siempre estar alerta"
			BtnEnviar.text = "Salir"
			BtnLimpiar.visible = false
			BtnIniciar.visible = false
			BtnEnviar.visible = true
			flujo = false
			return
	await get_tree().create_timer(3.0).timeout
	fade_transition.fade_to_scene("res://pantalla_final.tscn")	
	 # Replace with function body.

func verificarRecorrido() -> bool:
	if UserRecorrido.size() != recorrido.size():
		return false
	for x in range(recorrido.size()):
		if UserRecorrido[x] != recorrido[x]:
			return false
	return true

func _on_btn_limpiar_pressed() -> void:
	if bfs:
		limpiarVisual()
		UserRecorrido.clear()
		UserRecorrido.append(destino)
		lblRecorrido.text = str(recorStr())
	if dijstra:
		limpiarVisual()
		UserRecorrido.clear()
		UserRecorrido.append(origin)
		lblRecorrido.text = str(recorStr())	
	if flujo:
		current_path.clear()
		vertActual = null
		BtnEnviar.disabled = true
		_update_path_display()
	pass # Replace with function body.
func _on_boton_ayuda_pressed():
	panel_ayuda.visible = true
	
	

func _on_boton_continuar_pressed():
	panel_ayuda.visible = false


func _on_boton_continuar_2_pressed() -> void:
	panelCiber.visible = false
