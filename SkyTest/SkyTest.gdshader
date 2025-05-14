shader_type sky;
render_mode use_half_res_pass;
render_mode use_quarter_res_pass;

uniform int RaysPerPixel = 1;
uniform int MaxBounces = 2;
uniform float RayDivergeStrength;
uniform float FocusDistance;

uniform sampler2D testImage : filter_nearest;

uniform vec2 imageoffset = vec2(0);

uniform float[1280] seeds;

struct Sphere {
	vec3 position;
	float radius;
	vec3 color;
	float roughness;
	vec3 emissionColor;
	float specular;
	float emissionStrength;
	float specularProbability;
};

struct Ray {
	vec3 origin;
	vec3 dir;
};

struct HitInfo {
	bool hit;
	float dst;
	vec3 hitPoint;
	vec3 normal;
	Sphere sphere;
};

const int Objects = 5;

uniform vec3[Objects] points;
uniform vec3[Objects] colors : source_color;
uniform float[Objects] radii;
uniform float[Objects] roughness;
uniform vec3[Objects] emissionColor : source_color;
uniform float[Objects] specular;


HitInfo SphereCheckCollision(Ray ray, Sphere sphere) {
	HitInfo hitinfo = HitInfo(false, 0.0, vec3(0,0,0), vec3(0,0,0), sphere);
	vec3 offsetOrigin = ray.origin - sphere.position;

	float a = dot(ray.dir, ray.dir);
	float b = 2.0 * dot(offsetOrigin, ray.dir);
	float c = dot(offsetOrigin, offsetOrigin) - sphere.radius * sphere.radius;

	float discriminant = b * b - 4.0 * a * c;

	if (discriminant >= 0.0) {
		float dst = (-b - sqrt(discriminant)) / (2.0 * a);

		if (dst >= 0.0) {
			hitinfo.hit = true;
			hitinfo.dst = dst;
			hitinfo.hitPoint = ray.origin + ray.dir * dst;
			hitinfo.normal = normalize(hitinfo.hitPoint - sphere.position);
		}
	}
	return hitinfo;
}

HitInfo CalculateCollision(Ray ray, Sphere[Objects] spheres) {
	HitInfo closestHit;
	closestHit.hit = false;
	closestHit.dst = pow(10,5);
	for (int k = 0; k < Objects; k++) {
		HitInfo hi = SphereCheckCollision(ray, spheres[k]);
		if (hi.hit) {
			closestHit.hit = true;
			if (hi.dst < closestHit.dst) {
				closestHit.dst = hi.dst;
				closestHit.sphere = hi.sphere;
				closestHit.normal = hi.normal;
				closestHit.hitPoint = hi.hitPoint;
				closestHit.sphere = hi.sphere;
			}
		}
	}

	return closestHit;
}

float noise(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.25, 10.356))* 23.12 * fract(.99393)) * 5054.53);
	//return fract(sin(dot(uv, vec2(12.25, 10.356 + mod(TIME * 14.23, 1.0)))* 23.12) * 5054.53);
}

float RandomNormalDistribution(inout float prev) {
	prev = noise(vec2(prev, fract(14.23) * 1.1));
	float theta = 2.0 * PI * prev;
	float rho = sqrt(-2.0 * log(noise(vec2(prev,noise(vec2(prev, theta))))));
	return rho * cos(theta);
}


vec3 RandomDirection(float rng) {
	float seed = rng;
	float x = RandomNormalDistribution(seed);
	float y = RandomNormalDistribution(seed);
	float z = RandomNormalDistribution(seed);
	return normalize(vec3(x,y,z));
}

vec3 GetReflected(vec3 incoming, HitInfo hitInfo) {
	vec3 d = normalize(incoming);
	vec3 n = normalize(hitInfo.normal);
	float prod = dot(d, n);
	vec3 outgoing = normalize(d - n * (2.0 * prod));
	//return outgoing * sign(dot(normalize(d), n));
	return outgoing;
}

//this is insane. Change this to ensure the ray cannot dive into the sphere or
//bounce back at the camera.
vec3 DiffuseReflected(vec3 incoming, HitInfo h) {
	vec3 direction = RandomDirection(incoming.x * 0.01 + incoming.y * 0.1 + incoming.z);
	return direction * sign(dot(normalize(direction), h.normal));
}

vec3 lerp(vec3 st, vec3 end, float t) {
	t = clamp(t, 0, 1);
	return vec3((st.x * (1.0-t) + end.x * t),(st.y * (1.0-t) + end.y * t),(st.z * (1.0-t) + end.z * t));
}

float flerp(float st, float end, float t) {
	t = clamp(t, 0, 1);
	return (st * (1.0-t) + end * t);
}

vec3 GetEnvironmentLight(Ray ray, vec2 sky_c) {
	Ray r = Ray(ray.origin + ray.dir * 800.0, -ray.dir);
	Sphere s = Sphere(POSITION, 400.0, vec3(0),0.0, vec3(0), 0.0, 0.0, 0.0);
	HitInfo hi = SphereCheckCollision(r,s);
		vec3 n = -hi.normal;
		vec2 uv;
		uv.x = 0.5 + atan(n.x, n.z) / (2.0 * PI);
		uv.y = 0.5 + asin(n.y) / PI;
	if (hi.hit) {
		//return vec3(0.2);
		//return ray.dir;
		return texture(testImage,uv + imageoffset).rgb;
	}
	return vec3(0);
}

vec3 Trace(Ray ray, float seed, Sphere[Objects] spheres, vec2 sky_C) {
	vec3 incomingLight = vec3(0,0,0);
	vec3 rayColor = vec3(1,1,1);

	for (int i = 0; i <= MaxBounces; i++) {
		HitInfo hitInfo = CalculateCollision(ray, spheres);
		if(hitInfo.hit) {
			ray.origin = hitInfo.hitPoint;
			vec3 Diffuse = DiffuseReflected(ray.dir * seed, hitInfo);
			vec3 PerfectReflection = GetReflected(ray.dir, hitInfo);
			//bool isSpecularBounce = hitInfo.sphere.specular >= mod(noise(vec2(14.23, seed)), 1.0);
			//ray.dir = normalize(hitInfo.normal + PerfectReflection + Diffuse); //
			vec3 emittedLight = hitInfo.sphere.emissionColor;
			//ray.dir = lerp(Diffuse, PerfectReflection, (1.0 - hitInfo.sphere.roughness) * float(isSpecularBounce) ) ;
			ray.dir = lerp(Diffuse, PerfectReflection, (1.0 - hitInfo.sphere.roughness)) ;
			//ray.dir = PerfectReflection;
			incomingLight += emittedLight * rayColor;

			float light_strength = clamp(dot(hitInfo.normal, ray.dir), 0.2, 1.0);
			//ray.dir = lerp(Diffuse, PerfectReflection, (1.0 - hitInfo.sphere.roughness));
			//rayColor *= lerp(hitInfo.sphere.color, vec3(1,1,1), float(isSpecularBounce));
			rayColor *= hitInfo.sphere.color * light_strength * 2.0;
			//rayColor *= lerp(normalize(hitInfo.normal - POSITION - hitInfo.hitPoint), vec3(1,1,1), float(isSpecularBounce));
			//rayColor *= lerp(texture(testImage, ((CameraPosition - hitInfo.hitPoint).xz + TIME + vec2(1,1))/2.0).xyz, vec3(1,1,1), float(isSpecularBounce));
			//rayColor *= lerp(hitInfo.viewspaceNormal, vec3(1,1,1), float(isSpecularBounce));
			//rayColor *= lerp(hitInfo.normal, vec3(1,1,1), float(isSpecularBounce));
			/*
		} else if (i == 0 ){
			incomingLight += vec3(0);
			break;*/
		} else {
			incomingLight += GetEnvironmentLight(ray, sky_C) * rayColor;
			break;
		}
	}

	return incomingLight;
}

vec2 RandomPointInCircle(float seed) {
	float angle = RandomNormalDistribution(seed);
	vec2 pointOnCircle = vec2(cos(angle), sin(angle));
	return pointOnCircle * sqrt(RandomNormalDistribution(seed));
}

void sky() {
	if (!AT_QUARTER_RES_PASS) {
	//if (AT_HALF_RES_PASS) {
		COLOR = vec3(0,0,0);
		Sphere spheres[Objects];
		for (int i = 0; i < Objects; i++) {
			spheres[i].color = colors[i];
			spheres[i].position = points[i];
			spheres[i].radius = radii[i];
			spheres[i].roughness = roughness[i];
			spheres[i].emissionColor = emissionColor[i];
			spheres[i].specular = specular[i];
		}
		Ray r;
		for(int b = 0; b < RaysPerPixel; b++) {
			vec3 RayOrigin = POSITION;
			vec3 target = EYEDIR;

			r.origin = RayOrigin;
			r.dir = target;
			COLOR += (Trace(r, seeds[b % 10] + seeds[b / 10], spheres, SKY_COORDS)) * 1.0/float(RaysPerPixel);
			//COLOR += (Trace(r, TIME + float(b) * 1.2234, spheres, SKY_COORDS)) * 1.0/float(RaysPerPixel);
		}

		float divisor = 1.0 / float(RaysPerPixel);
		//COLOR = COLOR * divisor;
	}
	else {
		COLOR = QUARTER_RES_COLOR.rgb;
		//COLOR = HALF_RES_COLOR.rgb;
	}
}