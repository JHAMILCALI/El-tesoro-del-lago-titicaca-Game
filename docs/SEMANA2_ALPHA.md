# Semana 2 — Prototipo Alpha 0.1 "El Tesoro del Lago Titicaca" (Misión de Sigilo)

## Funcionalidades implementadas

- **[COMPLETADO]** Proyecto ejecutable en Godot 4.x
- **[COMPLETADO]** Protagonista Pasco con movimiento top-down en 8 direcciones y visibilidad garantizada (`z_index = 10`)
- **[COMPLETADO]** Sistema de carrera (Shift) y movimiento fluido
- **[COMPLETADO]** Mecánica de distracción: Lanzamiento de piedras (**`Q`**) que genera una onda de sonido (`NoiseArea`)
- **[COMPLETADO]** IA de Patrulla Española evolucionada: estados `PATROL` -> `SUSPICIOUS` (*"¿Qué fue eso?"*) -> `INVESTIGATE` -> `RETURN` -> `PATROL` (además de `ALERT` y `CAPTURE`)
- **[COMPLETADO]** Sistema de colisiones físicas (CharacterBody2D / StaticBody2D)
- **[COMPLETADO]** Cámara 2D suave siguiendo a Pasco
- **[COMPLETADO]** Escenario Nivel 1: El Convoy del Tesoro evolucionado como misión de sigilo narrativa
- **[COMPLETADO]** Interacción y diálogo ampliado con Huita (NPC)
- **[COMPLETADO]** Evento narrativo: Conversación secreta entre soldados españoles antes de la casa
- **[COMPLETADO]** Casa abandonada con zona interior (`HouseInterior.tscn`) y recogida del tesoro
- **[COMPLETADO]** Fase de **Escape Final**: activación de patrulla de persecución/escape tras recoger el tesoro
- **[COMPLETADO]** Sistema de 9 estados narrativos (`StoryState` 0 al 8)
- **[COMPLETADO]** Sistema de checkpoints (Inicio, Huita, Casa, Tesoro)
- **[COMPLETADO]** HUD dinámico con objetivos narrativos, notificaciones temporales (`OCULTO`, `RUIDO DETECTADO`, `ALERTA`, etc.) y modal final
- **[COMPLETADO]** Menú Principal navegable (Jugar Nivel 1, Prototipo Barca, Salir)
- **[COMPLETADO]** Prototipo independiente de la Barca (`BoatPrototype.tscn`) con aceleración por remo (Shift)

---

## Archivos Creados / Modificados

### Configuración
- `project.godot` (Asignación de acción `throw_stone` tecla `Q`, resolución 1280x720)

### Scripts (`scripts/`)
- `scripts/pasco.gd` (Control del protagonista, orientación y lanzamiento de piedras `Q`)
- `scripts/stone.gd` (Proyectil de piedra y disparo de ruido al impactar)
- `scripts/noise_area.gd` (Area2D de distracción auditiva para patrullas)
- `scripts/spanish_patrol.gd` (IA de patrulla, investigación de ruidos, alerta y captura)
- `scripts/huita.gd` (Proximidad e interacción de Huita)
- `scripts/level01_convoy.gd` (Flujo narrativo de 9 estados, diálogos, conversación secreta, fase de escape y checkpoints)
- `scripts/dialogue_box.gd` (Gestor de cuadros de diálogo)
- `scripts/hud.gd` (Gestor de HUD, objetivos y fin de demo)
- `scripts/house_interior.gd` (Lógica del interior de la casa y tesoro)
- `scripts/boat_prototype.gd` (Mecánica de navegación de la barca)
- `scripts/main_menu.gd` (Navegación del menú principal)

### Escenas (`scenes/`)
- `scenes/objects/Stone.tscn`
- `scenes/objects/NoiseArea.tscn`
- `scenes/main/MainMenu.tscn`
- `scenes/levels/Level01_Convoy.tscn`
- `scenes/levels/HouseInterior.tscn`
- `scenes/characters/Pasco.tscn`
- `scenes/characters/Huita.tscn`
- `scenes/enemies/SpanishPatrol.tscn`
- `scenes/prototypes/BoatPrototype.tscn`
- `scenes/ui/HUD.tscn`
- `scenes/ui/DialogueBox.tscn`

### Documentación (`docs/`)
- `docs/SEMANA2_ALPHA.md`

---

## Controles del Juego

| Acción | Teclas Asignadas |
|---|---|
| Moverse | **W, A, S, D** o **Flechas de Dirección** |
| Correr / Remo Rápido | **Shift** |
| Lanzar Piedra (Distracción) | **Q** |
| Interactuar / Avanzar Diálogo | **E** o **Enter** |
| Pausa / Salir a Menú | **Escape (Esc)** |

---

## Flujo de Estados Narrativos (0 al 8)

1. **Estado 0 (Inicio):** *"Explora el sendero y encuentra a Huita."* -> Mensaje: *"El camino parece tranquilo, pero hay presencia enemiga cerca."*
2. **Estado 1 (Primera patrulla):** *"Evita a la patrulla y llega hasta Huita."* -> Mensaje: *"Usa los arbustos para ocultarte o presiona Q para lanzar piedras."*
3. **Estado 2 (Huita encontrada):** *"Habla con Huita."*
4. **Estado 3 (Misión activada):** Diálogo ampliado con Huita -> *"Encuentra la casa abandonada y recupera el tesoro."*
5. **Estado 4 (Conversación escuchada):** Diálogo de soldados españoles -> *"Llega a la casa antes que ellos."*
6. **Estado 5 (Casa alcanzada):** *"Entra en la casa abandonada."*
7. **Estado 6 (Tesoro recogido):** *"Sal de la casa."* -> Mensaje: *"TESORO RECUPERADO"*.
8. **Estado 7 (Escape iniciado):** Activación de patrulla de persecución -> *"Escapa de la zona antes de que te encuentren."*
9. **Estado 8 (Nivel completado):** Llegada al punto seguro -> *"Tesoro recuperado. El camino al lago está despejado."* -> **ALPHA 0.1 COMPLETADO**.
