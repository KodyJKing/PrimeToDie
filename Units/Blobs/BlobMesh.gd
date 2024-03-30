extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mat : ShaderMaterial = get_surface_override_material(0)
	var bodies = get_children(false)
	
	var t = Time.get_ticks_usec() / 1e+6
	var s = sin(t) + 5.0
	var s2 = sin(t * 0.1) * .5 + .5
	
	# Pull bodies toward center
	for body: RigidBody3D in bodies:
		for body2: RigidBody3D in bodies:
			var p = body.global_position
			var p2 = body2.global_position
			var d = p2 - p
			var l = max(d.length(), 0.5)
			var repel = 0.9 * d.normalized() / (l * l) * s
			var attract = d / (l * l) * 4
			var f = (attract - repel) * 0.25 * s2
			body.apply_central_force(f)
			body2.apply_central_force(-f)
			
			if randf() < 0.01:
				body.apply_central_impulse(Vector3(0, delta * 8 * s2, 0))
	
	# Update material
	var blobs = [] #PackedFloat32Array()
	var i = 0
	for body in bodies:
		var p = body.global_position
		blobs.append(p.x)
		blobs.append(p.y)
		blobs.append(p.z)
		blobs.append(0.25 + sin(i * 0.3) * 0.1)
		i += 1
	mat.set_shader_parameter("blobs", blobs)
	mat.set_shader_parameter("numBlobs", bodies.size())
