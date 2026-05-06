shader_type canvas_item;

uniform vec4 key_color : source_color = vec4(0.118, 1.0, 0.0, 1.0); // #1EFF00
uniform float tolerance : hint_range(0.0, 1.0) = 0.2;
uniform float softness : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // distance between pixel color and key color
    float dist = distance(tex_color.rgb, key_color.rgb);

    // smooth edge instead of harsh cutoff
    float alpha = smoothstep(tolerance, tolerance + softness, dist);

    COLOR = vec4(tex_color.rgb, tex_color.a * alpha);
}