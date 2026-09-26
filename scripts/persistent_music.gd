extends AudioStreamPlayer

# Vive en la raíz del árbol para sobrevivir a reload_current_scene() y a la pausa.
# Se libera sola en cuanto la escena activa deja de ser la de `scene_path`.
var scene_path: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().scene_changed.connect(_on_scene_changed)

func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path != scene_path:
		queue_free()
