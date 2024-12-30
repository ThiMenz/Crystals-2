shader_type spatial;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_disable;

uniform sampler2D fadeTexture;

uniform sampler2D noise;
uniform float distortion_intensity = .1;
uniform vec2 distortion_tiling = vec2(1., 1.);
uniform vec2 distortion_offset_speed;

uniform float erosion_speed = .5;
uniform float erosion_max_offset = .5;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

uniform vec3 emissionVec: source_color;

uniform sampler2D fadeCurve;

uniform float CUSTOM_TIME = .0;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

}

void fragment() {
	vec2 cur_uv = UV;
	
	float animTime = fract(CUSTOM_TIME);//fract(TIME * 1.2);
	
	// - - Distortion - -
	vec2 noise_uv = cur_uv * distortion_tiling - distortion_offset_speed;
	float noise_tex = texture(noise, noise_uv).r;
	cur_uv += noise_tex * distortion_intensity;
	
	vec4 albedo_tex = texture(texture_albedo, cur_uv);
	vec4 fade_tex = texture(fadeTexture, cur_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	

	vec4 erosion_tex = texture(noise, cur_uv);
	float erosion_min = (animTime * .7 + fade_tex.r) - .3;
	float erosion_max = erosion_min + erosion_max_offset;
	float erosion_val = smoothstep(erosion_min, erosion_max, erosion_tex.r);

	//1. - fade_tex.r

	float shadeMult = 
	texture(
		fadeCurve, 
		vec2(animTime + fade_tex.r - .5)
	).r; //clamp(fade_tex.r - sin(TIME * 10.), 0., 1.);
	ALPHA *= albedo.a * albedo_tex.a * shadeMult * erosion_val; //* fade_tex.r;
	
	EMISSION.rgb = emissionVec;
	
	/*fract( // Relative Anim Time
				TIME * .9 // Anim Speed 
				//+ fade_tex.r * .2) // Trail Length 
				//,0., 1. <- clamp version (one time anim)
			)*/
}