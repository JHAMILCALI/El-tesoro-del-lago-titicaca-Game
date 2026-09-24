# Sprites de la barca

Generados con la herramienta integrada `image_gen`, guardados como PNG con transparencia. Los recursos anteriores se conservan.

- `assets/sprites/boat_crewed_v2.png`: dos viajeros y el tesoro.
- `assets/sprites/boat_empty_v2.png`: casco vacío alineado con la versión tripulada.
- `assets/sprites/boat_oar_v2.png`: remo independiente, usado a ambos lados.
- `scenes/objects/PlayerBoatVisual.tscn`: escena compartida por el muelle del nivel 1 y la barca navegable. El movimiento de los remos lo controla `scripts/player_boat_visual.gd`; cambia según la entrada de navegación y el modo de remo rápido.

## Prompts

### Barca tripulada

Create ONE production-quality transparent RGBA sprite for a 2D top-down Lake Titicaca adventure game. Single wooden rowboat with exactly TWO Andean travelers aboard, true orthographic overhead view with slight visibility of faces/clothes like classic Zelda 16-bit pixel art. Bow points straight UP, stern down, perfectly centered vertical hull, symmetrical boat construction, crisp clean chunky pixels readable at 90 pixels hull length. Beautiful warm honey-brown timber, darker outer gunwale, subtle carved geometric Andean ornament at bow, distinct planks, two benches, clear strong silhouette. Forward passenger near upper bench: young man with short dark hair wearing a turquoise/teal Andean poncho with narrow yellow/red trim, seated facing the stern. Middle passenger: woman with two long black braids, red woven blouse, darker skirt, facing up toward the bow, arms bent toward port/starboard gunwales ready to row. Exactly these TWO people only. One small tightly wrapped striped textile treasure bundle with a subtle gold mask glint secured at stern; clearly cargo not a third head/person. No separate heads, no duplicated people. IMPORTANT: NO OARS in this image; they will be animated separately in engine. NO water, foam, wake, external shadow, background, ground, text, labels, frame, sprite sheet. Real transparent alpha outside hull. The entire boat must fit with 10% empty transparent margin above and below, hull about 42% of canvas width and 80% of canvas height, use a square canvas. Light from upper left, attractive restrained shading, not photorealistic or vector. A single still sprite, not an animation sheet.

### Barca vacía (edición de la tripulada)

Edit this exact boat sprite into its EMPTY version. Remove both people and the treasure bundle entirely, restoring matching wooden benches and floor underneath. Keep every part of the hull, bow ornament, gunwale, colors, lighting, pixel-art style, scale, position, canvas dimensions and transparent outline EXACTLY aligned with the source. Do not move, resize or redesign the boat. No oars. Genuine transparent background. One boat, no text.

### Remo

Create ONE isolated wooden rowboat oar as a production transparent PNG game sprite. Crisp handcrafted 16-bit top-down pixel art matching a warm honey-brown wooden Andean rowboat. ONE single straight wooden shaft with a long rounded paddle blade at LEFT and a short handle at RIGHT. Perfectly horizontal centerline, all geometry visible from directly overhead. Thin shaft, slightly broader elongated blade, small warm wood grain details, dark readable outline, light from upper left. Occupy central 80% of image width, about 12% of image height, generous transparent margins. Genuine RGBA transparency, no water, no shadow outside object, no boat, no people, no second oar, no text, no sheet, no frame. Single oar only.

### Transparencia del remo (edición)

Background extraction only: keep the wooden oar exactly as shown, identical position, shape, wood colors and crisp pixel art. Remove ALL black background and ALL orange glow/halo/shadows outside the wooden oar. Replace everything outside the hard pixel silhouette of the oar with genuine fully transparent alpha (0). No glow or translucent haze anywhere outside. Do not add elements. Preserve the horizontal oar, broad blade on left and small handle right.

