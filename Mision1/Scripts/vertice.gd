class_name Vertice


var adyacentes = []  # Array de servidores adyacentes
var name = ""        # String para el nombre del servidor
var posicion # Vector de posicion para la posicion en grafica
var id = 0           # int para el ID
var funcionalidad = "" # String para guardar la funcion del servidor
var is_origin := false
var pista

func _init(id, name = "", funcionalidad = "", origen = false, pista = ""):
	self.id = id
	self.name = name
	self.funcionalidad = funcionalidad
	self.is_origin = origen
	self.pista = pista

# Métodos
func get_adyacencia() -> Array:
	return adyacentes

func set_adyacencia(adyacencia: Array):
	self.adyacentes = adyacencia

func addAdyacente(vertice: Vertice):
	self.adyacentes.append(vertice)
