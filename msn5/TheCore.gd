extends Control

# -----Constantes----- 
const LINEA_DE_CONEXION_NODOS = "conexion"
const LINEA_DE_RECORRIDO_NODOS = "recorrido"
const LINEA_DE_DIJKSTRA_NODOS = "dijkstra"
const LINEA_DE_RECONSTRUCCION_NODOS = "reconstruccion"
const LINEA_DE_FLUJO_NODOS = "flujo"
const LINEA_DE_FLUJO_MAX_NODOS = "flujoMaximo"
const MAX_WRONG_CLICKS = 5

# Variables visuales (se mantienen igual)
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

var num_vertices = 9
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
var wrong_clicks = 0
var original_capacity = []
var flow_network = []
var residual_graph = []
var target_flow
var total_flow_sent := 0
var packets_sent := 0
var current_path = []
var pesoTotal = 0

var camino_optimo = []   
var esperando_click = false

func _ready() -> void:
	print("=== INICIANDO JUEGO ===")
	grafo = Grafo.new()
	fade_transition.visible = false
	panelCiber.visible = true
	panel_ayuda.visible = false
	
	iniciarMatrices()	
	
	for i in range(num_vertices):
		var angle = (2 * PI * (i+num_vertices)) / 10
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
	print("Dibujando grafo inicial con ", grafo.vertices.size(), " vértices")
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
				
func dibujarLineas(origen, destin, funcion, lab = true, correcto = true, tipo = "NoDirigida"):
	print("Dibujando línea: ", origen.id, " -> ", destin.id, " (", funcion, ")")
	
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
		var peso = grafo.matriz_peso[origen.id][destin.id]
		var p0 = arista.line.points[0]
		var p1 = arista.line.points[1]
		var center = (p0 + p1) / 2
		var dir = (p1 - p0).normalized()
		var perp = Vector2(-dir.y, dir.x)
		var offset_distance = 20.0
		var label = Label.new()
		label.text = str(peso)		
		label.position = center + perp * (offset_distance * 3)
		label.rotation = atan2(dir.y, dir.x)		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.size = Vector2(50, 20)
		label.pivot_offset = label.size / 2		
		if not has_node("Label," + str(origen.id) + "," + str(destin.id)):
			label.name = "Label," + str(origen.id) + "," + str(destin.id)
		else:
			label.name = "Label," + str(destin.id) + "," + str(origen.id)		
		PanelGrafo.add_child(label)
		labels.append(label)
		label.visible = true

func dibujarConexionKruskal():
	print("=== CREANDO SOLO EDGELINES ===")
	prepararKruskal()
	
	
	var todas_aristas = []
	var aristas_vistas = {}
	
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]
		for ady in vertice.adyacentes:
			var clave_min = min(vertice.id, ady.id)
			var clave_max = max(vertice.id, ady.id)
			var clave = str(clave_min) + "_" + str(clave_max)
			
			if not aristas_vistas.has(clave):
				aristas_vistas[clave] = true
				var peso = grafo.getPeso(vertice, ady)
				todas_aristas.append({
					"u": vertice, 
					"v": ady, 
					"peso": peso,
					"clave": clave
				})
	
	print("Aristas para crear: ", todas_aristas.size())
	
	
	var z_counter = 10
	for arista_data in todas_aristas:
		var edge_control = Control.new()
		var edge_script = preload("res://edge_line_2.gd")
		
		if edge_script:
			edge_control.set_script(edge_script)
			PanelGrafo.add_child(edge_control)
			
			await get_tree().process_frame
			
			if edge_control.has_method("connect_nodes"):
				# ASIGNAR z_index ÚNICO y CRECIENTE
				edge_control.z_index = z_counter
				z_counter += 1
				
				edge_control.connect_nodes(arista_data["u"], arista_data["v"], arista_data["peso"])
				edge_control.connect("edge_selected", Callable(self, "_on_edge_selected"))
				lineasConexion.append(edge_control)
				
				print("✅ EdgeLine: ", arista_data["u"].id, "-", arista_data["v"].id, " | z_index: ", edge_control.z_index)
func verificar_edge_lines():
	print("=== VERIFICACIÓN DE EDGE LINES ===")
	var edge_controls = []
	for child in PanelGrafo.get_children():
		# Verificar por métodos únicos de EdgeLine
		if child.has_method("connect_nodes") and child.has_method("set_correct"):
			edge_controls.append(child)
	
	print("EdgeLines encontrados en PanelGrafo: ", edge_controls.size())
	for edge in edge_controls:
		print("  - EdgeLine: ", edge.node_a.id, " - ", edge.node_b.id, " en posición: ", edge.global_position)

func limpiarVisual():
	print("Limpiando visuales...")
	for x in lineasVisuales:
		if is_instance_valid(x):
			x.queue_free()
	lineasVisuales.clear()
	time_remaining=120
	
func limpiarConexiones():
	print("Limpiando ", lineasConexion.size(), " conexiones...")
	for x in lineasConexion:
		if is_instance_valid(x):
			x.queue_free()
	lineasConexion.clear()
	
	for label in labels:
		if is_instance_valid(label):
			label.queue_free()
	labels.clear()
	
	for label in labels:
		if is_instance_valid(label):
			label.queue_free()
	labels.clear()
	time_remaining = 120
	
func dibujarGrafoNuevo():
	for i in range(num_vertices):
		var vertic1 = grafo.searchVertice(i)
		for j in range(num_vertices):
			if i != j:
				if randf() < prob_conexion:
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
	print("=== EDGE SELECTED CALLBACK ===")
	print("Edge seleccionada: ", edge.node_a.id, " - ", edge.node_b.id)
	
	if start and kruskal:
		print("Ejecutando kruskal_click...")
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
# ------------------ Kruskal CORREGIDO ----------------------------
func prepararKruskal():
	print("=== LIMPIANDO PARA KRUSKAL ===")
	
	# Limpiar solo las conexiones visuales, NO los botones
	for child in PanelGrafo.get_children():
		if child is Button:
			continue  
		child.queue_free()
	
	lineasConexion = []  
	KruskalLineas.clear()
	UserRecorrido.clear()
	labels.clear()
	
	# INICIALIZACIÓN CORREGIDA del parent array
	parent.resize(num_vertices)
	for i in range(num_vertices):
		parent[i] = i  # Cada nodo es su propio padre inicialmente
	
	print("Parent inicializado: ", parent)
	print("Limpieza completada - lineasConexion vacío: ", lineasConexion.size())

func kruskal_click(edge):
	print("=== KRUSKAL CLICK ===")
	print("Procesando arista: ", edge.node_a.id, " - ", edge.node_b.id)
	print("Peso: ", edge.weight)
	
	var n1 = edge.node_a.id
	var n2 = edge.node_b.id
	
	print("Parent antes: ", parent)
	
	var root1 = find_kruskal(n1)  # Usar find_kruskal
	var root2 = find_kruskal(n2)  # Usar find_kruskal
	
	print("Raíz de ", n1, ": ", root1)
	print("Raíz de ", n2, ": ", root2)
	
	if root1 != root2:
		print(">>> CONEXIÓN VÁLIDA - Uniendo componentes")
		union_kruskal(root1, root2)  # Usar union_kruskal
		KruskalLineas.append(edge)
		UserRecorrido.append(edge)
		
		# Marcar como correcta
		print("Llamando set_correct(true) en edge")
		edge.set_correct(true)
		
		lblRecorrido.text = "Conexiones: " + str(KruskalLineas.size()) + "/" + str(num_vertices - 1)
		lblIntro.text = "¡Correcto! Conexión añadida. Peso total: " + str(_calcular_peso_total())
		
		print("Parent después: ", parent)
		print("Aristas seleccionadas: ", KruskalLineas.size())
		
		# Verificar si se completó
		if KruskalLineas.size() == num_vertices - 1:
			print(">>> KRUSKAL COMPLETADO!")
			start = false
			var peso_total = _calcular_peso_total()
			lblIntro.text = "¡Árbol completado! Peso total: " + str(peso_total)
			BtnEnviar.visible = true
	else:
		print(">>> CONEXIÓN INVÁLIDA - Crearía ciclo")
		print("Llamando set_correct(false) en edge")
		edge.set_wrong()  # Cambiar a set_wrong para consistencia
		lblIntro.text = "Esta conexión crearía un ciclo. Intenta con otra."
		wrong_clicks += 1
		
		# Verificar si se excedió el límite de errores
		if wrong_clicks >= MAX_WRONG_CLICKS:
			lblIntro.text = "Demasiados errores. Reiniciando Kruskal..."
			wrong_clicks = 0
			# Reiniciar Kruskal
			_on_btn_limpiar_pressed()
			prepararKruskal()
			dibujarConexionKruskal()

# FUNCIÓN FIND CORREGIDA con compresión de camino
func find_kruskal(i: int) -> int:
	if parent[i] != i:
		parent[i] = find_kruskal(parent[i])  # Compresión de camino
	return parent[i]

# FUNCIÓN UNION CORREGIDA
func union_kruskal(root1: int, root2: int):
	# Siempre hacer parent[root2] = root1 para mantener consistencia
	parent[root2] = root1
	print("Unión: parent[", root2, "] = ", root1)

func _calcular_peso_total() -> int:
	var total = 0
	for edge in KruskalLineas:
		total += edge.weight
	return total




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
		lblIntro.text = "Intenta construir una red conectada más rápida y segura. Selecciona las conexiones en orden de menor peso para construir el árbol de expansión mínima."
		start = true
		BtnIniciar.visible = false
		BtnEnviar.visible = false
		# Asegurar que todo esté listo
		dibujarConexionKruskal()
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
		kruskal = true
		
		# Limpiar y preparar para Kruskal
		limpiarVisual()
		limpiarConexiones()
		mostrarPesos(false)
		
		# Inicializar Kruskal
		call_deferred("dibujarConexionKruskal")
		
		BtnIniciar.visible = true
		BtnEnviar.visible = false
		BtnLimpiar.visible = false
		start = false
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
	if kruskal:  # AÑADIR ESTE CASO
		limpiarVisual()
		UserRecorrido.clear()
		KruskalLineas.clear()
		wrong_clicks = 0
		# Reinicializar parent array
		for i in range(num_vertices):
			parent[i] = i
		lblRecorrido.text = "Conexiones: 0/" + str(num_vertices - 1)
		lblIntro.text = "Kruskal reiniciado. Selecciona las conexiones nuevamente."
		# Volver a dibujar las edges
		dibujarConexionKruskal()
	if flujo:
		current_path.clear()
		vertActual = null
		BtnEnviar.disabled = true
		_update_path_display()
	
func _on_boton_ayuda_pressed():
	panel_ayuda.visible = true

func _on_boton_continuar_pressed():
	panel_ayuda.visible = false

func _on_boton_continuar_2_pressed() -> void:
	panelCiber.visible = false
