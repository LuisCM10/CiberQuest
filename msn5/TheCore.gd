extends Control

# -----Constantes----- 
const LINEA_DE_CONEXION_NODOS = "conexion"
const LINEA_DE_RECORRIDO_NODOS = "recorrido"
const LINEA_DE_CONEXION_PESOS_NODOS = "Pesos"
const LINEA_DE_DIJKSTRA_NODOS = "dijkstra"
const LINEA_DE_RECONSTRUCCION_NODOS = "reconstruccion"
const LINEA_DE_CONEXION_CAPACIDAD_NODOS = "Capacidad"
const LINEA_DE_FLUJO_NODOS = "flujo"
const LINEA_DE_FLUJO_MAX_NODOS = "flujoMaximo"
const MAX_WRONG_CLICKS = 5
# Variable visuales
@onready var PanelGrafo = $PanGrafo
@onready var lblIntro =$VBoxContainer/LblIntruccion
@onready var lblTime = $VBoxContainer/LblTime
@onready var lblRecorrido = $VBoxContainer/lblRecorrido
@onready var BtnIniciar = $VBoxContainer/BtnIniciar
@onready var BtnEnviar = $VBoxContainer/BtnEnviar
@onready var BtnLimpiar = $VBoxContainer/BtnLimpiar
@onready var view = get_viewport_rect().size * 0.3

var grafo = Grafo.new()

# Variables control
var bfs = true
var dijstra = false
var kruskal = false
var flujo = false
var start = false
var time_remaining := 120.0

var num_vertices = 9
var prob_conexion = 0.4
var lineasConexion = []
var lineasVisuales = []

var vertActual = null
var aristaActual = null
var origin
var destino

var UserRecorrido = []
var recorrido = []
var KruskalLineas = []
var parent = []
var wrong_clicks = 0
var original_capacity 
var flow_network
var residual_graph
var target_flow


func _ready() -> void:
	for i in range(num_vertices):		
		var angle = (2 * PI * i) / 10
		var x = 150 + view[0] * cos(angle)
		var y = 90 + view[1] * sin(angle)
		var positions = Vector2(x, y)
		var vertice = Nodo.new(i, positions)
		grafo.add_vertice(vertice)
		
	# Conectar vértices con pesos y capacidades aleatorios
	for i in range(num_vertices):
		var vertic1 = grafo.searchVertice(i)
		for j in range(num_vertices):
			if i != j:
				if randf() < prob_conexion:
					var vertic2 = grafo.searchVertice(j)
					var peso = randf_range(1.0, 10.0)
					var capacidad = randi_range(1, 20)
					grafo.connect_vertice(vertic1, vertic2, peso, capacidad)
	dibujarGrafo()
	
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
				dibujarLineas(vertice, ady, LINEA_DE_CONEXION_NODOS)
	pass
	
func dibujarLineas(origen, destin, funcion, correcto = true):
	var arista = Arista.new(origen, destin)	
	match funcion:
		LINEA_DE_CONEXION_NODOS:
			arista.connect("linea_presionada", Callable(self, "_on_linea_presionada").bind(arista))
			arista.tipo = "NoDirigida"
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
			if destino.is_origin:
				arista.color = Color(53.064, 244.585, 0.0, 1.0)
			else: 
				arista.color = Color(0.185, 0.416, 1.0, 1.0)
			if not correcto:
				arista.color = Color(1.0, 0.0, 0.102, 1.0)
			lineasVisuales.append(arista)
	PanelGrafo.add_child(arista)
	PanelGrafo.add_child(arista)

func _on_linea_presionada(arista):
	aristaActual = arista
	pass
	
func _on_nodo_clicked(vertice):
	vertActual = vertice
	if start and bfs:
		if not UserRecorrido.has(vertActual):
			BFS()
			lblRecorrido.text = str(recorStr())
		else:
			lblIntro.text = "El nodo "+ str(vertActual.id) + " ya se encuentra en el recorrido"

func recorStr() -> Array:
	var recor = []
	for x in UserRecorrido:
		recor.append(x.id)
	return recor
	
#----------------- Kruskal ----------------------------
func kruskal_click(edge):
	var n1 = edge.origen.id     
	var n2 = edge.destino.id    

	if find(n1) != find(n2):
		union(n1, n2)
		KruskalLineas.append(edge)
		edge.set_correct(true)
	else:
		edge.set_correct(false)
		wrong_clicks += 1
		if wrong_clicks >= MAX_WRONG_CLICKS:
			#show_defeat_message()
			pass
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

func BFS () :
	if vertActual == origin:
		lblIntro.text = "Has hallado el backup del sistema es necesario enviar una señal de victoria."
		BtnEnviar.visible = true
	for x in UserRecorrido:
		if x.adyacentes.has(vertActual):
			UserRecorrido.append(vertActual)
			var verificar = recorrido[UserRecorrido.size()-1] == UserRecorrido[UserRecorrido.size()-1]
			dibujarLineas(x,vertActual,LINEA_DE_RECORRIDO_NODOS,verificar)
			if not verificar:
				UserRecorrido.pop_back()
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
	var parent = []
	parent.resize(num_vertices)
	for i in range(num_vertices):
		parent[i] = -1
	var visited = []
	visited.resize(num_vertices)
	for i in range(num_vertices):
		visited[i] = false

	var queue = [origin]
	visited[origin.id] = true
	while queue.size() > 0:
		var u = queue.pop_front()
		for v in range(num_vertices):
			if !visited[v] and res[u][v] > 0:
				parent[v] = u
				visited[v] = true
				queue.append(v)
	
	if !visited[destino.id]:
		return []
	
	var path = []
	var v = destino.id
	while v != origin.id:
		path.insert(0, v)
		v = parent[v]
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
	#CUADRADO VIajando
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	particle.material = material
	
	if line and line.points.size() > 1:
		particle.position = line.points[0] - Vector2(4, 4)
	else:
		particle.position = start - Vector2(4, 4)
	
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

#------------------------- Controles juego ----------------------------------------------------------
func _on_btn_iniciar_pressed() -> void:
	if bfs:
		iniciarRecorridos()
		start = true
		BtnIniciar.visible = false
		BtnEnviar.visible = false
	if dijstra:
		start = true
		BtnIniciar.visible = false
		BtnEnviar.visible = false
	if kruskal:
		start = true
		BtnIniciar.visible = false
		BtnEnviar.visible = false
	pass # Replace with function body.


func _on_btn_enviar_pressed() -> void:
	if bfs:
		if UserRecorrido.size() == recorrido.size():
			lblIntro.text = "Felicidades, completaste tu primer reto. Ahora es hora de hallar nuestro camino mas corto hasta el nodo "+str(origin.id)+" para hallar el backup del sistema."
			bfs = false
			destino = origin
			origin = UserRecorrido[0]
			UserRecorrido.clear()
			recorrido.clear()
			dijstra = true
			mostrarPesos()
			start = false
		else:
			lblIntro.text = "Parece que aun te falta algun nodo por recorrer. Sera necesario revisar."
	if dijstra:
		if verificarRecorrido():
			UserRecorrido.clear()
			recorrido.clear()
			lblIntro.text = "Felicidades, completaste tu segundo reto. Ahora es hora de construir un sistema seguro y liviano hasta cada uno de nuestros servidores."
			dijstra = false
		else:
			lblIntro.text = "Parece que ese no es el camino mas corto. Hemos perdido recursos al intentar enviarlo, intentalo de nuevo."
			BtnIniciar.visible = false
			BtnEnviar.visible = false
	if kruskal:
		lblIntro.text = "Felicidades, completaste tu tercer reto. Ahora es hora de verificar que el backup llege hasta cada uno de nuestros servidores."
		kruskal = false
		UserRecorrido.clear()
		recorrido.clear()
		mostrarCapacidad()
		
	pass # Replace with function body.

func verificarRecorrido() -> bool:
	if UserRecorrido.size() != recorrido.size():
		return false
	for x in range(recorrido.size()):
		if UserRecorrido[x] != recorrido[x]:
			return false
	return true
	
func limpiarVisual():
	for x in lineasVisuales:
		x.queue_free()
	
func mostrarPesos():
	for x in lineasConexion:
		var lbl = x.label
		lbl.text = str(grafo.getPeso(x.origen, x. destino))
		x.mostrarLabel()
		
func mostrarCapacidad():
	for x in lineasConexion:
		var lbl = x.label
		lbl.text = str(grafo.getFlujoUsado(x.origen, x.destino))+"/"+str(grafo.getFlujoMax(x.origen, x.destino))
		x.mostrarLabel()

func _on_btn_limpiar_pressed() -> void:
	limpiarVisual()
	UserRecorrido.clear()
	UserRecorrido.append(destino)
	lblRecorrido.text = str(recorStr())	
	pass # Replace with function body.
