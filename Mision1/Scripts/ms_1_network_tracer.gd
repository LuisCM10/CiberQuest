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
@onready var BotSigNivel = $Panel/ButtonSig
@onready var LabelIntru = $Panel2/PanelInfo/Label
@onready var panelCiber = $PanelCiber
@onready var lExplicaCiber = $PanelCiber/ExplicaCiber
@onready var boton_continuar2 = $PanelCiber/BotonContinuar2
@onready var boton_ayuda = $BotonAyuda
@onready var panel_ayuda = $PanelAyuda
@onready var boton_continuar = $PanelAyuda/BotonContinuar
@onready var lblRecorrido = $Panel/LblRecorrido
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
var recorrido = []
var UserRecorrido = []
var dfs = false
var bfs = false
var origin
var json_data
@onready var sizes = [PanGrafo.size[0] * 0.46, PanGrafo.size[1] * 0.44]


func _ready():
	# Crear vértices con datos del JSON (carga el JSON como antes)
	var file = FileAccess.open("res://Mision1/data/servidores.json", FileAccess.READ)
	json_data = JSON.parse_string(file.get_as_text())
	file.close()
	panelCiber.visible = true
	panel_ayuda.visible = false	
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
	BotSigNivel.visible = false
	dibujar_grafo()


func _on_servidor_clicked(vertice):
	VertIni = vertice
	print(VertIni.name)
	if !PanServ.visible:
		PanServ.visible = true	
	LabelName.text = VertIni.name
	LabelFunct.text = VertIni.funcionalidad
	if PanPista.visible and not recorrido.has(VertIni):
		PanPista.visible = false
	elif not PanPista.visible and recorrido.has(VertIni):
		PanPista.visible = true
	if in_recorrido and not UserRecorrido.has(VertIni):
		if bfs:
			BFS()
		elif dfs:
			DFS()
	if in_recorrido and UserRecorrido.has(VertIni):
		LabelIntru.text = "El " +VertIni.name+" ya ha sido escaneado, intenta con otro servidor."
	
func _on_button_bfs_pressed() -> void:	
		iniciarRecorridos("bfs")

func iniciarRecorridos(tipo):
	if not VertIni:
		LabelIntru.text = "Necesitas elegir un nodo en el cual iniciar la busqueda de Nemesis."
		return
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
	UserRecorrido.append(VertIni)
	lblRecorrido.text = str(recorStr())
	LabelIntru.text = "Haz elegido iniciar la busqueda con " + VertIni.name + ". \nHas encontrado una pista en los nodos recorridos, leela para guiarte bien." + "\nTen en cuenta que debes añadir los servidores en orden de las manecillas del reloj iniciando desde firewall "
	LabelPista.text = VertIni.pista
	if tipo == "bfs":
		bfs = true
		recorrido = grafo.bfs(VertIni)
	elif tipo == "dfs":
		dfs = true
		recorrido = grafo.dfs(VertIni)

func BFS () :
	for x in UserRecorrido:
		if x.adyacentes.has(VertIni):
			verificarNodoIngresado(x)
			await get_tree().create_timer(3).timeout
			return
	

func _on_button_dfs_pressed() -> void:
		iniciarRecorridos("dfs")
	
func DFS ():
	var i = UserRecorrido.size()-1
	while i > 0 and not UserRecorrido[i].adyacentes.has(VertIni):
		i-=1
	if UserRecorrido[i].adyacentes.has(VertIni):
		verificarNodoIngresado(UserRecorrido[i])
		await get_tree().create_timer(3).timeout
		return

func recorStr() -> Array:
	var recor = []
	for x in UserRecorrido:
		recor.append(x.name)
	return recor
	
func verificarNodoIngresado(nodoPrev):
	UserRecorrido.append(VertIni)
	var verificar = recorrido[UserRecorrido.size()-1] == VertIni		
	if not verificar:
		dibujarRecorrido(nodoPrev,VertIni, false)
		UserRecorrido.remove_at(UserRecorrido.size()-1)
		LabelIntru.text = "Lo siento, el " +VertIni.name+" no es el siguiente servidor a escanear."
		await get_tree().create_timer(3).timeout
		return
	dibujarRecorrido(nodoPrev,VertIni)
	LabelIntru.text = "Bien hecho, sigue asi, " +VertIni.name+" esta siendo escaneado."
	LabelPista.text = VertIni.pista
	await get_tree().create_timer(3).timeout
	if VertIni == origin:
		LabelName.text = origin.name
		LabelFunct.text = origin.funcionalidad
		LabelPista.text = "“Rastreo completado. Has encontrado el nodo raíz del virus, el "+origin.name+". Siguiente misión: calcular la ruta más segura para aislarlo.”"
		LabelIntru.text = "Bien hecho. Has detectado el servidor raiz del ataque de Nemesis." + "\nEl" +origin.name+"."
		in_recorrido = false
		if bfs:
			bfs = false
		else:
			dfs = false
		BotSigNivel.visible = true
	lblRecorrido.text = str(recorStr())
	return

func dibujarRecorrido(node, prev, correcto = true) -> void:
	var color
	if correcto:
		color = Color(0.185, 0.416, 1.0, 1.0)
		if prev.is_origin:
			color = Color(51.59, 38.892, 0.0, 1.0)
	else:
		color = Color(0.864, 0.15, 0.185, 1.0)
	crearLinea(node, prev, color,"recorrido",  5)
	

func _on_button_sig_pressed() -> void:
	if recorrido.has(origin):
		ControlGame.avanzarNivel()
		get_tree().change_scene_to_file("res://niveles.tscn")


func _on_button_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://niveles.tscn")
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
		button.connect("pressed", Callable(self, "_on_servidor_clicked").bind(vertice))
		PanGrafo.add_child(button)
		for ady in vertice.get_adyacencia():
			var indice_ady = grafo.vertices.find(ady)
			if indice_ady > i:  # Evita duplicar líneas
				crearLinea(vertice, indice_ady, Color(1.0, 1.0, 1.0, 1.0))


func crearLinea(vertice, indice_ady, color, nasme = "conexion", width = 2):
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
	else: 
		anim = 0.6
		linea.tipo = nasme
		linea.name = nasme + "_" + vertice.name + "_" + node_b.name
	linea.start_point = start_point
	linea.end_point = end_point
	linea.origen = vertice
	linea.destino = node_b
	linea.width = width
	linea.default_color = color
	linea.duracion = anim
	PanGrafo.add_child(linea)


func _on_boton_continuar_2_pressed() -> void:
	panelCiber.visible = false


func _on_boton_ayuda_pressed() -> void:
	panel_ayuda.visible = true


func _on_boton_continuar_pressed() -> void:
	panel_ayuda.visible=false
