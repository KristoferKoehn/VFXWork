shader_type sky;
render_mode use_quarter_res_pass;

uniform bool environment = false;
uniform vec3 GroundColor : source_color;
uniform vec3 SkyColorHorizon : source_color;
uniform vec3 SkyColorZenith : source_color;
uniform vec3 SunLightDirection;
uniform float SunFocus;
uniform float SunIntensity;

uniform int RaysPerPixel = 1;
uniform int MaxBounces = 2;
uniform vec3 CameraPosition = vec3(0,0,0);
uniform vec3 CameraRotation = vec3(0,0,0);
uniform float NearPlane = 0.1;
uniform float FarPlane = 8;
uniform float FOV = 2;
uniform float AspectRatio = 2;
uniform float RayDivergeStrength;
uniform float FocusDistance;

uniform sampler2D testImage;

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
uniform float[Objects] emisionStrength;
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
	return fract(sin(dot(uv * TIME, vec2(12.25, 10.356))* 23.12 * fract(.99393)) * 5054.53);
	//return fract(sin(dot(uv, vec2(12.25, 10.356 + mod(TIME * 14.23, 1.0)))* 23.12) * 5054.53);
}

float RandomNormalDistribution(inout float prev) {
	prev = noise(vec2(prev, fract(14.23) * 1.1));
	float theta = 2.0 * PI * prev;
	float rho = sqrt(-2.0 * log(noise(vec2(prev,noise(vec2(prev, theta))))));
	return rho * cos(theta);
}

vec3 RandomDirection(float rng) {
	float seed = 14.23;
	float x = RandomNormalDistribution(seed);
	seed = seed * 2.303;
	float y = RandomNormalDistribution(seed);
	seed = seed * 2.343;
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

vec3 DiffuseReflected(vec3 incoming) {
	vec3 direction = RandomDirection(14.23 + TIME);
	return direction * sign(dot(normalize(incoming), direction));
}

vec3 lerp(vec3 st, vec3 end, float t) {
	t = clamp(t, 0, 1);
	return vec3((st.x * (1.0-t) + end.x * t),(st.y * (1.0-t) + end.y * t),(st.z * (1.0-t) + end.z * t));
}

float flerp(float st, float end, float t) {
	t = clamp(t, 0, 1);
	return (st * (1.0-t) + end * t);
}

vec3 GetEnvironmentLight(Ray ray) {
	if (environment) {
		float skyGradientT = pow(smoothstep(0, 0.4, ray.dir.y), 0.35);
		vec3 skyGradient = lerp(SkyColorHorizon, SkyColorZenith, skyGradientT);
		float sun = pow(max(0, dot(ray.dir, -SunLightDirection)), SunFocus) * SunIntensity;

		float groundToSkyT = smoothstep(-0.6, 0.01, ray.dir.y);
		float sunMask = groundToSkyT >= 1.0 ? 1.0 : 0.0;
		return lerp(skyGradient,GroundColor,  groundToSkyT) + sun * sunMask;
	}
	//return ray.dir;
	return vec3(0);
}

vec3 Trace(Ray ray, inout float seed, Sphere[Objects] spheres) {
	vec3 incomingLight = vec3(0,0,0);
	vec3 rayColor = vec3(1,1,1);

	for (int i = 0; i <= MaxBounces; i++) {
		HitInfo hitInfo = CalculateCollision(ray, spheres);
		if(hitInfo.hit) {
			ray.origin = hitInfo.hitPoint;
			vec3 Diffuse = (DiffuseReflected(hitInfo.normal));
			vec3 PerfectReflection = GetReflected(ray.dir, hitInfo);
			bool isSpecularBounce = hitInfo.sphere.specular >= mod(noise(vec2(14.23, seed)), 1.0);
			//ray.dir = normalize(hitInfo.normal + PerfectReflection + Diffuse); //
			vec3 emittedLight = hitInfo.sphere.emissionColor * hitInfo.sphere.emissionStrength;
			ray.dir = lerp(Diffuse, PerfectReflection, (1.0 - hitInfo.sphere.roughness) * float(isSpecularBounce) ) ;
			incomingLight += emittedLight * rayColor;
			//rayColor *= lerp(hitInfo.sphere.color, vec3(1,1,1), float(isSpecularBounce));
			rayColor *= lerp(normalize(hitInfo.normal - CameraPosition - hitInfo.hitPoint), vec3(1,1,1), float(isSpecularBounce));
			//rayColor *= lerp(texture(testImage, ((CameraPosition - hitInfo.hitPoint).xz + TIME + vec2(1,1))/2.0).xyz, vec3(1,1,1), float(isSpecularBounce));
			//rayColor *= lerp(hitInfo.viewspaceNormal, vec3(1,1,1), float(isSpecularBounce));
			//rayColor *= lerp(hitInfo.normal, vec3(1,1,1), float(isSpecularBounce));
		} else {
			incomingLight += GetEnvironmentLight(ray) * rayColor;
			break;
		}
	}

	return incomingLight;
}

vec2 GetNDC(vec2 uv) {
	float x_ndc = 2.0 * uv.x - 1.0;
	float y_ndc = 1.0 - 2.0 * uv.y;
	return vec2(x_ndc, y_ndc);
}


vec2 RandomPointInCircle(float seed) {
	float angle = RandomNormalDistribution(seed);
	vec2 pointOnCircle = vec2(cos(angle), sin(angle));
	return pointOnCircle * sqrt(RandomNormalDistribution(seed));
}

void sky() {
	if (AT_QUARTER_RES_PASS) {
		COLOR = vec3(0,0,0);
		Sphere spheres[Objects];
		for (int i = 0; i < Objects; i++) {
			spheres[i].color = colors[i];
			spheres[i].position = points[i];
			spheres[i].radius = radii[i];
			spheres[i].roughness = roughness[i];
			spheres[i].emissionColor = emissionColor[i];
			spheres[i].emissionStrength = emisionStrength[i];
			spheres[i].specular = specular[i];
		}

		Ray r;
		for(int b = 0; b < RaysPerPixel; b++) {

			//State = clamp(fract(State), 0, TIME/ 30.0);
			float Seed = fract(noise(EYEDIR.xy) * 1.0 - TIME * 0.00432122);
			/*
			messing with projection matrix to get field of view working. It's not working.
			*/

			vec3 RayOrigin = POSITION;
			vec3 target = EYEDIR;

			r.origin = RayOrigin;
			r.dir = target;
			int bounces = 0;
			COLOR += (Trace(r, Seed, spheres));
		}

		float divisor = 1.0 / float(RaysPerPixel);
		COLOR = COLOR * divisor;
	}
	else {
		//do nothing
		COLOR = QUARTER_RES_COLOR.rgb;
	}
}