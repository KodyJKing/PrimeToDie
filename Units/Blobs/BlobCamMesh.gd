@tool
extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		var cam = EditorInterface.get_editor_viewport_3d(0).get_camera_3d();
		global_position = cam.global_position
	else:
		global_position = get_parent().global_position
