extends Control

@onready var LabelPista = $Panel2/PanelPista/ColorRect/LabelPista
@onready var LabelName = $Panel2/PanelInfoServer/PanLabelName/LabelName
@onready var LabelFunct = $Panel2/PanelInfoServer/ColorRect/LabelFunct
@onready var PanGrafo = $Grafo
@onready var PanInfo = $Panel2/PanelInfo
@onready var PanServ = $Panel2/PanelInfoServer
@onready var PanPista = $Panel2/PanelPista
@onready var BotBFS = $Panel2/PanelInfo/ButtonBFS
@onready var BotDFS = $Panel2/PanelInfo/ButtonDFS
@onready var BotSig = $Panel2/ButtonSig
@onready var LabelIntru = $Panel2/PanelInfo/Label
# Número de servidores
var num_servidores = 10

# Probabilidad de conexión (0.0 a 1.0)
var prob_conexion = 0.5

# Grafo inicializado
var grafo = Grafo.new()

# Vertice inicial del recorrido o elegido actual para informacion
var VertIni : Vertice
# Variable de control del recorrido
var in_recorrido = false
var visitados = []
var recorrido = []
var cola = []
var pila = []
var ite = 0
var dfs = false
var bfs = false
var origin
var json_data
@onready var sizes = [PanGrafo.size[0] * 0.46, PanGrafo.size[1] * 0.44]


func _ready():
	# Crear vértices con datos del JSON (carga el JSON como antes)
	var file = FileAccess.open("res://data/servidores.json", FileAccess.READ)
	json_data = JSON.parse_string(file.get_as_text())
	file.close()
	
	for i in range(json_data.size()):
		var vertice = Vertice.new(i, json_data[i]["name"], json_data[i]["functionality"], json_data[i]["is_origin"], json_data[i]["hidden_message"])
		var angle = (2 * PI * i) / 10
		var x = 292.5 + sizes[0] * cos(angle)
		var y = 145 + sizes[1] * sin(angle)
		var positions = Vector2(x, y)
		vertice.posicion = positions
		grafo.add_vertice(vertice)
		
	
	# Generar conexiones aleatorias
	for i in range(num_servidores):
		var vertic1 = grafo.searchVertice(i)
		for j in range(i + 1, num_servidores):
			if randf() < prob_conexion:
				var vertic2 = grafo.searchVertice(j)
				grafo.connect_vertice(vertic1, vertic2)
	PanServ.visible = false
	PanPista.visible = false
	BotSig.visible = false
	dibujar_grafo()


func _on_servidor_clicked(index: int):
	if !PanServ.visible:
		PanServ.visible = true
	VertIni = grafo.searchVertice(index)
	LabelName.text = VertIni.name
	LabelFunct.text = VertIni.funcionalidad
	if PanPista.visible and not recorrido.has(VertIni):
		PanPista.visible = false
	elif not PanPista.visible and recorrido.has(VertIni):
		PanPista.visible = true
	
		
func _process(delta: float) -> void:
	if in_recorrido and recorrido.has(VertIni):
		LabelPista.text = VertIni.pista
		
	if recorrido.has(origin):
		BotSig.text = "Seguir a la siguiente mision"
		LabelName.text = origin.name
		LabelFunct.text = origin.funcionalidad
		LabelPista.text = "“Rastreo completado. Has encontrado el nodo raíz del virus, el "+origin.name+". Siguiente misión: calcular la ruta más segura para aislarlo.”"
		LabelIntru.text = "Bien hecho. Has detectado el nodo raiz del virus." + "\n" +origin.name+"."

func iniciarRecorridos():
	in_recorrido = true
	var origin_index = randi() % grafo.vertices.size()
	origin = grafo.vertices[origin_index]
	while origin == VertIni or VertIni.adyacentes.has(origin):
		origin_index = randi() % grafo.vertices.size()
		origin = grafo.vertices[origin_index]
	origin.is_origin = true
	BotBFS.visible = false
	BotDFS.visible = false
	PanPista.visible = true
	LabelIntru.text = "Haz elegido iniciar la busqueda con "+VertIni.name+". \nHas encontrado una pista en los nodos recorridos, leela para guiarte bien"

func _on_button_bfs_pressed() -> void:
	if VertIni:
		iniciarRecorridos()
		bfs = true
		cola.append(VertIni)
		visitados.append(VertIni)
		BFS()
		BotSig.visible = true
	else:
		LabelIntru.text = "Elige un nodo para comenzar la busqueda"

func BFS () :
	var top = ite +3
	while ite < top or cola.is_empty():
		var node = cola.pop_front()
		if node:
			recorrido.append(node)
			if node.is_origin:
				ite = top		
			if not recorrido.is_empty():
				dibujarRecorrido(node, recorrido.size()-1)
				await get_tree().create_timer(2).timeout
			for neighbor in node.adyacentes:
				if neighbor not in visitados:
					visitados.append(neighbor)
					cola.append(neighbor)		
		ite+=1
	return recorrido
	

func _on_button_dfs_pressed() -> void:
	if VertIni:
		iniciarRecorridos()
		dfs = true
		pila.append(VertIni)
		visitados.append(VertIni)
		DFS()
		BotSig.visible = true
	else:
		LabelIntru.text = "Elige un nodo para comenzar la busqueda"
		 # Replace with function body.
	
func DFS ():
	var top = ite + 2
	while ite < top or pila.is_empty():
		var node = pila.pop_back() # Sacar del final
		recorrido.append(node)
		if node.is_origin:
			ite = top
		if not recorrido.is_empty():
			dibujarRecorrido(node, recorrido.size()-1)
			await get_tree().create_timer(2).timeout
		for neighbor in node.adyacentes:
			if not neighbor in visitados:
				visitados.append(neighbor)
				pila.append(neighbor)
		ite += 1
	return recorrido
	
func dibujarRecorrido(node, prev) -> void:
	if prev < 0:
		return
	if not node.adyacentes.has(recorrido[prev]):
		dibujarRecorrido(node, prev-1)
		return
	var x = recorrido[prev]
	var color 
	if node.is_origin:
		color = Color(255,0,0)
	else: 
		color = Color(0.185, 0.416, 1.0, 1.0)
	crearLinea(x, color, 5, node, "recorrido")
	

func _on_button_sig_pressed() -> void:
	if recorrido.has(origin):
		get_tree().quit()
	elif dfs:
		BotSig.visible = false
		DFS()
		BotSig.visible = true
		print(pila.size())
	elif bfs:
		BotSig.visible = false
		BFS()
		BotSig.visible = true
		print(cola.size())


func _on_button_exit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
	
	
func dibujar_grafo():
	for i in range(grafo.vertices.size()):
		var vertice = grafo.vertices[i]
				
		var button = Button.new()
		button.name = vertice.name + "Button"
		button.icon = load(json_data[i]["icon"])
		button.icon_alignment = HORIZONTAL_ALIGNMENT_FILL
		button.expand_icon = true
		button.size = Vector2(40, 40)
		button.position = vertice.posicion
		button.flat = true
		button.connect("pressed", Callable(self, "_on_servidor_clicked").bind(i))
		PanGrafo.add_child(button)
		# Dibujar conexiones (líneas)
		for ady in vertice.get_adyacencia():
			var indice_ady = grafo.vertices.find(ady)
			if indice_ady > i:  # Evita duplicar líneas
				crearLinea(vertice,Color(1.0, 1.0, 1.0, 1.0), 2, indice_ady)


func crearLinea(vertice, color, width, indice_ady, name = "conexion"):
	var linea = conexion.new()
	var node_b
	if indice_ady is int:
		node_b = grafo.searchVertice(indice_ady)
	else:
		node_b = indice_ady
	var pos_a = vertice.posicion + Vector2(40, 40) / 2
	var pos_b = node_b.posicion + Vector2(40, 40) / 2
	var radius_a = max(24,46) / 2
	var radius_b = max(24,46) / 2
	var dir = (pos_b - pos_a).normalized()		
	var start_point = pos_a + dir * radius_a
	var end_point = pos_b - dir * radius_b
	var anim = 1
	if name == "conexion":
		linea.name = vertice.name + "_"+ node_b.name
		linea.start_point = end_point
		linea.end_point = start_point
	else: 
		anim = 0.6
		if has_node(vertice.name + "_"+ node_b.name):			
			linea.start_point = start_point
			linea.end_point = end_point	
		else:
			linea.start_point = start_point
			linea.end_point = end_point
		linea.name = name + "_" + vertice.name + "_" + node_b.name
	linea.width = width
	linea.default_color = color
	linea.duracion = anim
	PanGrafo.add_child(linea)
