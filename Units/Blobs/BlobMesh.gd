extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mat : ShaderMaterial = get_surface_override_material(0)
	var bodies = get_children(false)
	
	var t = Time.get_ticks_usec() / 1e+6
	var s = sin(t)
	
	# Pull bodies toward center
	for body: RigidBody3D in bodies:
		for body2: RigidBody3D in bodies:
			var p = body.global_position
			var p2 = body2.global_position
			var d = p2 - p
			var l = max(d.length(), 0.5)
			var repel = 1.1 * d.normalized() / (l * l) * (s + 4.0)
			var f = (d - repel) * 0.25
			body.apply_central_force(f)
			body2.apply_central_force(-f)
			
			if randf() < 0.0001:
				body.apply_central_impulse(Vector3(0, delta * 25, 0))
	
	# Update material
	var blobs = [] #PackedFloat32Array()
	for body in bodies:
		var p = body.global_position
		blobs.append(p.x)
		blobs.append(p.y)
		blobs.append(p.z)
		blobs.append(0.25)
	mat.set_shader_parameter("blobs", blobs)
	mat.set_shader_parameter("numBlobs", bodies.size())
