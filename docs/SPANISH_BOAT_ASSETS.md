# Barca española — Nivel 2

PNG generado con la herramienta integrada `image_gen`, editando la barca actual del jugador para conservar casco, escala, perspectiva y estilo.

- `assets/sprites/spanish_rowboat_v2.png`: casco con dos soldados, armaduras y detalles rojos; fondo transparente.
- `scenes/enemies/SpanishRowboat.tscn`: barca enemiga reutilizable con la IA existente. La utilizan tanto los tres enemigos iniciales como los refuerzos.
- Comparte `scenes/objects/PlayerBoatVisual.tscn` y el PNG de remos con el jugador. Los sprites de los remos rotan alrededor de sus empuñaduras, sin cambiar de casco o soldados entre fotogramas. La cadencia depende de la velocidad real; se recoge al detenerse, ocultarse o desactivar la IA.
- Conserva la captura por proximidad y las velocidades de las oleadas. La proa apunta en la dirección de desplazamiento.

## Prompt utilizado

Edit this exact game sprite to create the SPANISH PATROL version of the SAME small wooden rowboat. Preserve the exact centered vertical hull, dimensions, position on canvas, timber construction, warm wood palette, gunwale, benches, overhead perspective, pixel scale and transparent outer silhouette. Bow still points straight UP. Replace the TWO Andean travelers with exactly TWO 16th-century Spanish soldiers: forward seated soldier facing stern with simple steel morion helmet, small breastplate, muted crimson sleeves and brown boots; middle rower facing bow wearing steel helmet seen from behind, crimson doublet, leather belt, bent arms/hands in precisely the same rowing positions as the original woman. Recognizable tiny crisp armor details without overcrowding. Replace the treasure bundle at stern with neatly stowed plain canvas supply roll and one small red-and-gold shield or folded pennant, contained entirely inside the hull. Replace the Andean bow ornament with a modest dark red painted panel with simple gold edge. The small boat must remain the same type as the reference, NOT a ship or galleon: NO mast, NO sail, NO tall flagpole, NO cannon, NO third person. NO OARS: existing separate wooden oars will be animated in engine. Transparent RGBA background, no water, no shadow outside, no foam, no text, no frame, no sheet. Match the original sharp handcrafted 16-bit pixel art and upper-left light exactly. Keep full outline and margins aligned for drop-in replacement in the existing shared boat scene.

