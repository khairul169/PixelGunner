extends MeshInstance

func _ready() -> void:
	var sf = SurfaceTool.new();
	sf.begin(Mesh.PRIMITIVE_TRIANGLES);
	
	var tris = [
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1)
	];
	
	sf.add_vertex(tris[0]);
	sf.add_vertex(tris[1]);
	sf.add_vertex(tris[2]);
	
	sf.add_vertex(tris[2]);
	sf.add_vertex(tris[3]);
	sf.add_vertex(tris[0]);
	
	sf.index();
	sf.generate_normals();
	var m = sf.commit();
	
	mesh = m;
