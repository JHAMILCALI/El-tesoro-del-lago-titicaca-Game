shader_type canvas_item;
render_mode unshaded;

// All grass, rocks and foam come from bordes.png. Keep the original atlas intact.
uniform sampler2D terrain_atlas : source_color, filter_nearest, repeat_disable;
uniform vec2 land_size = vec2(1352.0, 612.0);
uniform float border_width = 104.0;
uniform float corner_radius = 90.0;

// Distance along the rounded perimeter, so the shore also follows each corner.
float perimeter_position(vec2 p, vec2 size, float r) {
	float w = size.x - 2.0 * r;
	float h = size.y - 2.0 * r;
	float arc = 1.570796327 * r;
	if (p.y < r) {
		if (p.x < r) {
			return 2.0 * w + 2.0 * h + 3.0 * arc + atan(r - p.y, r - p.x) * r;
		}
		if (p.x > size.x - r) {
			return w + atan(p.x - size.x + r, r - p.y) * r;
		}
		return p.x - r;
	}
	if (p.y > size.y - r) {
		if (p.x > size.x - r) {
			return w + h + arc + atan(p.y - size.y + r, p.x - size.x + r) * r;
		}
		if (p.x < r) {
			return 2.0 * w + h + 2.0 * arc + atan(r - p.x, p.y - size.y + r) * r;
		}
		return w + h + 2.0 * arc + size.x - r - p.x;
	}
	if (p.x > size.x * 0.5) {
		return w + arc + p.y - r;
	}
	return 2.0 * w + h + 3.0 * arc + size.y - r - p.y;
}

void fragment() {
	vec2 atlas_size = vec2(textureSize(terrain_atlas, 0));
	vec2 p = floor(UV * (land_size + vec2(border_width))) - vec2(border_width * 0.5);
	vec2 q = abs(p - land_size * 0.5) - (land_size * 0.5 - vec2(corner_radius));
	float distance_to_coast = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner_radius;
	float along = perimeter_position(p, land_size, corner_radius);
	float across = clamp(0.5 + distance_to_coast / border_width, 0.0, 1.0);

	// The same grass variants used by the original ground, with correct atlas offsets.
	vec2 cell = floor(p / vec2(104.0, 102.0));
	float variant = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	vec2 grass_origin = vec2(1144.0, 214.0);
	if (variant > 0.80) {
		grass_origin = vec2(1144.0, 112.0);
	} else if (variant > 0.65) {
		grass_origin = vec2(728.0, 112.0);
	}
	vec2 tile_size = vec2(104.0, 102.0);
	vec2 tile_local = mod(p, tile_size);
	// Mirror adjacent samples and blend decorations only inside each tile to hide seams.
	vec2 grass_local = clamp(abs(mod(p, tile_size * 2.0) - tile_size), vec2(0.5), tile_size - vec2(0.5));
	vec4 base_grass = texture(terrain_atlas, (vec2(1144.0, 214.0) + grass_local) / atlas_size);
	vec4 decorated_grass = texture(terrain_atlas, (grass_origin + grass_local) / atlas_size);
	vec2 edge_distance = min(tile_local, tile_size - tile_local);
	vec4 grass = mix(base_grass, decorated_grass, smoothstep(4.0, 26.0, min(edge_distance.x, edge_distance.y)));

	// Three adjacent shoreline sections: grass inside, rock and foam, then lake outside.
	vec2 shore_uv = (vec2(314.0, 628.0) + vec2(mod(along, 314.0), across * 103.0) + vec2(0.5)) / atlas_size;
	vec4 shore = texture(terrain_atlas, shore_uv);
	COLOR = mix(grass, shore, smoothstep(0.0, 0.24, across));
	// Blend the outer water into the existing lake instead of leaving a square tile edge.
	COLOR.a *= 1.0 - smoothstep(0.78, 1.0, across);
}
