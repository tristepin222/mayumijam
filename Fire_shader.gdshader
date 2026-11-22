shader_type canvas_item;

uniform sampler2D NOISE_PATTERN : repeat_enable;
//add movement to the basemap
uniform vec2 scroll1 = vec2(0.5, 0.5);
uniform vec2 scroll2 = vec2(-0.3, 0.3);
//Rescale to adapt the sprite size
uniform vec2 noiseScale1 =  vec2(1.0, 1.0);
uniform vec2 noiseScale2 =  vec2(1.0, 1.0);
//gradient color
uniform sampler2D TONE_MAPPING;
//blur and intensity 
uniform float blur : hint_range(0.0, 7.0) = 3.0;
uniform float baseIntensity : hint_range(0.0, 0.5) = 0.1;
uniform float intensityFactor : hint_range(0.0, 5.0) = 1.5;

// Called for every pixel the material is visible on.
void fragment() {
    float tex_alpha = textureLod(TEXTURE, UV, blur).a;
    float pattern_intensity1 = texture(NOISE_PATTERN, UV * noiseScale1 + TIME * scroll1).r;
    float pattern_intensity2 = texture(NOISE_PATTERN, UV * noiseScale2 + TIME * scroll2).r;
    float intensity = tex_alpha * intensityFactor *
        (pattern_intensity1 * pattern_intensity2 + baseIntensity);
    COLOR = texture(TONE_MAPPING, vec2(intensity));
}