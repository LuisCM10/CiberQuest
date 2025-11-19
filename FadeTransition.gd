extends CanvasLayer

@onready var color_rect = ColorRect.new()

func _ready():
	color_rect.color = Color(0, 0, 0, 0)  # Negro transparente inicialmente
	add_child(color_rect)

# Función para cambiar escena con fade
func fade_to_scene(scene_path: String, fade_duration: float = 1.0):
	# Fade out (oscurecer)
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	# Cambiar escena
	get_tree().change_scene_to_file(scene_path)
	
	# Fade in (aclarar)
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, fade_duration)
	await tween.finished
