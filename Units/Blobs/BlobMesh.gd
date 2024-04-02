extends MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var mat: ShaderMaterial = get_surface_override_material(0)
	var bodies = get_children(false)
	
	var t = Time.get_ticks_usec() / 1_000_000.0
	var s = sin(t) * .5 + .5
	var s2 = sin(t * 0.25) * .5 + .5
	s2 = round(s2 * 3) / 3
	#s2 = 1
	#s = 1
	
	for body: RigidBody3D in bodies:
		var p = body.global_position
		
		# Repel from ground slightly.
		var h = p.y + 0.01
		var f = 1 / (h * h) * Vector3.UP
		body.apply_central_force(f)
		
		#body.gravity_scale = 1 - s2
		
		if randf() < 0.005:
			var randForce = Vector3()
			randForce.x = randf() * 2.0 - 1.0
			randForce.y = randf() * 2.0 - 1.0
			randForce.z = randf() * 2.0 - 1.0
			randForce = randForce.normalized() * 200 * s2
			body.apply_central_force(randForce)
		
		var inverseSum = 0
		
		# Attract/repel other blobs
		for body2: RigidBody3D in bodies:
			if body == body2:
				continue
			var p2 = body2.global_position
			var d = p2 - p
			var l = max(d.length(), 0.5)
			var repel =  d.normalized() / (l * l) * lerpf(6, 7, s)
			var attract = d / (l * l) * 4
			var f2 = (attract - repel) * 1.0 * s2
			body.apply_central_force(f2)
			body2.apply_central_force( - f2)
			
			inverseSum += 1 / (l * l * l * l)
		
		body.apply_central_force(-body.linear_velocity * inverseSum * 0.2 * s2)
	
	# Update material
	var blobs = PackedFloat32Array()
	for body in bodies:
		var p = body.global_position
		blobs.append(p.x)
		blobs.append(p.y)
		blobs.append(p.z)
		blobs.append(0.25)
	mat.set_shader_parameter("blobs", blobs)
	mat.set_shader_parameter("numBlobs", bodies.size())
