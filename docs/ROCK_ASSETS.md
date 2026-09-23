# Rocas del lago — Nivel 2

Tres PNG originales con transparencia, generados con la herramienta integrada `image_gen`. La lámina anterior `water_rock.png` se conserva, pero el nivel 2 ya no la utiliza.

## Uso en Godot

- Arrastra `scenes/objects/LakeRockRound.tscn`, `LakeRockCluster.tscn` o `LakeRockJagged.tscn` al nivel.
- Cada escena incluye el PNG, un cuerpo sólido `StaticBody2D` y un `CollisionPolygon2D` ajustado al contorno de la roca; la espuma exterior no es sólida.
- Las 15 rocas están colocadas en `LakeLevel02.tscn`, visibles y editables desde el editor. Se conservaron las posiciones de los obstáculos anteriores.
- El choque bloquea la barca, reduce su velocidad y la empuja en la dirección normal de contacto. El enfriamiento de 0,7 s evita repetir alertas cada fotograma.
- Los PNG se conservan sin recortar ni alterar. La escala y los contornos se definen en las escenas.

## lake_rock_round

Archivo: `assets/tiles/lake_rock_round.png`

Prompt utilizado:

Production game asset: ONE isolated rock obstacle sprite for a colorful 2D top-down Lake Titicaca pixel-art game. True overhead view, shallow visible rock facets, compact low mass rather than a tall cliff. Handcrafted crisp 16-bit pixel art, chunky readable gray granite facets, subtle olive green moss patches, dark brown wet stone at the waterline, a very thin white/cyan foam rim close around the rock footprint. Genuine transparent RGBA canvas outside that narrow rim, no background water, no blue square, no checkerboard pattern, no text, no frame, no sprite sheet or multiple disconnected objects. Centered complete silhouette with 12% empty transparent margin on all sides, square canvas. Must read clearly when displayed at 100-140 pixels wide in game. Upper-left soft light, restrained contrast, no external drop shadow. ONE obstacle only. A single squat rounded boulder, roughly circular asymmetric outline, a broad gray cap divided into four big facets, small moss patch on upper left.

## lake_rock_cluster

Archivo: `assets/tiles/lake_rock_cluster.png`

Prompt utilizado:

Production game asset: ONE isolated rock obstacle sprite for a colorful 2D top-down Lake Titicaca pixel-art game. True overhead view, shallow visible rock facets, compact low mass rather than a tall cliff. Handcrafted crisp 16-bit pixel art, chunky readable gray granite facets, subtle olive green moss patches, dark brown wet stone at the waterline, a very thin white/cyan foam rim close around the rock footprint. Genuine transparent RGBA canvas outside that narrow rim, no background water, no blue square, no checkerboard pattern, no text, no frame, no sprite sheet or multiple disconnected objects. Centered complete silhouette with 12% empty transparent margin on all sides, square canvas. Must read clearly when displayed at 100-140 pixels wide in game. Upper-left soft light, restrained contrast, no external drop shadow. ONE obstacle only. One connected cluster of three low boulders with a wide oval footprint, touching stones of different sizes, moss in the crevices. Compact connected silhouette, slightly wider than tall.

## lake_rock_jagged

Archivo: `assets/tiles/lake_rock_jagged.png`

Prompt utilizado:

Production game asset: ONE isolated rock obstacle sprite for a colorful 2D top-down Lake Titicaca pixel-art game. True overhead view, shallow visible rock facets, compact low mass rather than a tall cliff. Handcrafted crisp 16-bit pixel art, chunky readable gray granite facets, subtle olive green moss patches, dark brown wet stone at the waterline, a very thin white/cyan foam rim close around the rock footprint. Genuine transparent RGBA canvas outside that narrow rim, no background water, no blue square, no checkerboard pattern, no text, no frame, no sprite sheet or multiple disconnected objects. Centered complete silhouette with 12% empty transparent margin on all sides, square canvas. Must read clearly when displayed at 100-140 pixels wide in game. Upper-left soft light, restrained contrast, no external drop shadow. ONE obstacle only. One rugged angular boulder, irregular compact hexagonal silhouette, fractured gray granite surface with a narrow diagonal crack and just a little moss. Slightly taller than wide.

