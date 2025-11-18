extends Control

# Nodos principales
#@onready var fondo = $fondo
@onready var boton_inicio = $BotonInicio
@onready var boton_config = $BotonConfiguracion
@onready var boton_salir = $salir
@onready var panel = $PanelConfiguracion
@onready var labelJugar =$Jugar
@onready var labelSalir =$Salir
# Panel de configuración
@onready var boton_quitar_musica = $PanelConfiguracion/BotonQuitarMusica
@onready var boton_cerrar = $PanelConfiguracion/CerrarButton
#@onready var label_instrucciones = $PanelConfiguracion/LabelInstrucciones

# Íconos de música
@onready var icono_sonido = preload("res://sonido.png")
@onready var icono_mute = preload("res://sonido muteado.png")

func _ready():
	mostrar_Config(false)
	_actualizar_icono_musica()

# ===========================
# Funciones de botones
# ===========================

func _on_settings_pressed():
	mostrar_Config(true)

func _on_cerrar_button_pressed():
	mostrar_Config(false)

func _on_boton_quitar_musica_pressed():
	MusicaGlobal.toggle_musica()
	_actualizar_icono_musica()

func _on_salir_pressed():
	get_tree().quit()
	

func _on_boton_inicio_pressed():
	get_tree().change_scene_to_file("res://cinematica.tscn")
	print("Oprime boton inicio")
	labelJugar.visible = false
	labelSalir.visible=false

# ===========================
# Función de icono de música
# ===========================
func _actualizar_icono_musica():
	if MusicaGlobal.is_playing():
		boton_quitar_musica.texture_normal = icono_sonido
	else:
		boton_quitar_musica.texture_normal = icono_mute

func mostrar_Config(value: bool):
	_actualizar_icono_musica()
	boton_inicio.visible = not value
	boton_salir.visible = not value
	boton_config.visible = not value
	panel.visible = value
	labelJugar.visible = not value
	labelSalir.visible = not value
	
func mostrar() -> void:
	self.visible = true

func ocultar() -> void:
	self.visible = false
