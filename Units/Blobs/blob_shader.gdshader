shader_type spatial;
render_mode depth_prepass_alpha, shadows_disabled;
//render_mode depth_prepass_alpha;

uniform sampler2D noiseNorm;
uniform vec3 blobColor : source_color = vec3(.15, 0.0, .15);

uniform float alphaStepStart = 0.0;
uniform float alphaStepEnd = 0.3;

uniform float iridescenceSaturation : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D iridescenceNoise;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

float sphereSdf(vec3 p, vec3 pos, float r) {
	return length(pos - p) - r;
}

// https://iquilezles.org/articles/smin
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float mapSdf(vec3 p, float t) {
	float s1 = sphereSdf( p, vec3(.0, .0 ,.0), .5 );
	float s2 = sphereSdf( p, vec3(.0, 1.125 + sin(TIME) * .25 ,.0), .5);
	return smin(s1, s2, 0.5 + cos(TIME * 10.0) * .05 );
}

vec3 mapNormal(vec3 p, float t) {
	float epsilon = 0.001;
	float eInv = 1.0 / epsilon;
	vec2 d = vec2(epsilon, 0.0);
	float sdf0 = mapSdf(p, t);
	float dx = mapSdf(p + d.xyy, t) - sdf0;
	float dy = mapSdf(p + d.yxy, t) - sdf0;
	float dz = mapSdf(p + d.yyx, t) - sdf0;
	return vec3(dx * eInv, dy * eInv, dz * eInv);
}

float trace(vec3 ro, vec3 rd, float t, float sgn) {
    float epsilon = .01;
    float dist = .0;
	float maxDist = 200.0;
    for(int i = 0; i < 500 && dist < maxDist; i++) {
        float d = mapSdf(ro + rd * dist, t) * sgn;
        dist += d;
        if (d < epsilon) return dist;
    }
    return -1.0;
}

vec3 triplanar(vec3 p, vec3 n, sampler2D tex) {
	vec3 nx = vec3(1.0, 0.0, 0.0);
	vec3 ny = nx.yxy;
	vec3 nz = nx.yyx;
	vec3 cx = texture(tex, p.yz).xyz;
	vec3 cy = texture(tex, p.xz).xyz;
	vec3 cz = texture(tex, p.xy).xyz;
	float kx = abs(dot(nx, n));
	float ky = abs(dot(ny, n));
	float kz = abs(dot(nz, n));
	float k = kx + ky + kz;
	return (cx * kx + cy * ky + cz * kz) / k;
}

float luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 saturate(vec3 color, float s) {
	return mix(vec3(luma(color)), color, s);
}

void fragment() {
	float t = 0.0; // Make a uniform for this.
	vec3 wFwd = (INV_VIEW_MATRIX * vec4(-VIEW, 0.0)).xyz;
	vec3 wPos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	//ALPHA = 1.0;
	
	float d = trace(wPos, wFwd, t, 1.0);
	if (d < 0.0) {
		DEPTH = 1.0;
		ALPHA = 0.0;
	} else {
		CLEARCOAT = 2.0;
		CLEARCOAT_ROUGHNESS = .01;
		ROUGHNESS = 0.1;
		
		vec3 wHit = wPos + d * wFwd;
		vec3 wNorm = normalize(mapNormal(wHit, t));
		vec3 vNorm = (VIEW_MATRIX * vec4(wNorm, 0.0)).xyz;
		NORMAL = vNorm;
		//ALBEDO = (vNorm * .5 + .5) * 1.0;
		
        vec4 clipPos = (PROJECTION_MATRIX * VIEW_MATRIX * vec4(wHit, 1.0));
		float depth = clipPos.z / clipPos.w;
		DEPTH = depth;
		
		float thickness = max(trace(wHit + wFwd * .1, wFwd, t, -1.0), .1);
		float alpha = smoothstep(alphaStepStart, alphaStepEnd, thickness);
		
		vec3 s0 = wHit * .25 + vec3(sin(TIME * .5) * .05, TIME * 0.05, cos(TIME * .5) * .05);
		float blobLuma = luma(blobColor);
		float iridescence = blobLuma * .8 + .01;
		vec3 iridescenceCol = saturate(triplanar(s0, wNorm, iridescenceNoise), iridescenceSaturation);
		//ALBEDO = iridescenceCol * iridescence + blobColor;
		ALBEDO = mix(blobColor, iridescenceCol, iridescence);
		
		vec3 s1 = wHit + vec3(.0, TIME * .1, .0);
		vec3 s2 = wHit + vec3(TIME * .01, TIME * .05, .0);
		NORMAL_MAP = mix(triplanar(s1, wNorm, noiseNorm), triplanar(s2, wNorm, noiseNorm), .5);
		NORMAL_MAP_DEPTH = 1.0;
		
		if (alpha < .9) {
			vec3 wBackNorm = mapNormal(wHit + wFwd * thickness, t);
			vec3 vBackNorm = (VIEW_MATRIX * vec4(wBackNorm, 0.0)).xyz;
			vec2 uv = SCREEN_UV + vBackNorm.xy / vBackNorm.z * .01;
			ALBEDO = mix(texture(SCREEN_TEXTURE, uv).xyz, ALBEDO, alpha);
			//ALBEDO = vec3(1., 0., 0.);
		}
	}
}
