shader_type spatial;
render_mode cull_disabled, unshaded;

uniform sampler2D tex;
uniform vec3 c : source_color;
uniform float alpha = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = texture(tex, vec2(UV.x/6.0 + 5.0/12.0, UV.y - TIME*0.5)).rgb * c;
	//ALBEDO = vec3(UV, 0.0);
	ALPHA = clamp(texture(tex, vec2(UV.x/6.0 + 5.0/12.0, UV.y - TIME*0.5)).w * UV.y,0.0, 1.0) * alpha;
	//ALPHA = texture(tex, vec2(UV.x/4.0 + 3.0/8.0, UV.y + TIME)).w;
	// Called for every pixel the material is visible on.
}
