shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D tex;
uniform vec3 col : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(tex, UV).rgb * col;
	ALPHA = texture(tex, UV).a;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
