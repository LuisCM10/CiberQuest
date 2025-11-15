extends Node

@onready var musica: AudioStreamPlayer2D = $musica
var musica_activa := true

func _ready():
	if musica:
		musica.stream.loop = true
		if musica_activa:
			musica.play()

func toggle_musica():
	if not musica:
		return
	if musica.playing:
		musica.stop()
		musica_activa = false
	else:
		musica.play()
		musica_activa = true

func is_playing() -> bool:
	return musica_activa
