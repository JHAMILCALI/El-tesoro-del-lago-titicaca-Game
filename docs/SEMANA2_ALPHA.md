# Semana 2 — Prototipo Alpha 0.1 "El Tesoro del Lago Titicaca"

## Funcionalidades implementadas

- **[COMPLETADO]** Proyecto ejecutable en Godot 4.x
- **[COMPLETADO]** Protagonista Pasco con movimiento top-down en 8 direcciones
- **[COMPLETADO]** Sistema de carrera (Shift) y movimiento fluido
- **[COMPLETADO]** Sistema de colisiones físicas (CharacterBody2D / StaticBody2D)
- **[COMPLETADO]** Cámara 2D suave siguiendo a Pasco
- **[COMPLETADO]** Escenario prototipo Nivel 1: El Convoy del Tesoro
- **[COMPLETADO]** Interacción y proximidad con Huita (NPC)
- **[COMPLETADO]** Sistema de diálogo navegable (DialogueBox) con bloqueo de movimiento
- **[COMPLETADO]** Enemigo Patrulla Española con movimiento de patrulla entre puntos A y B
- **[COMPLETADO]** Sistema de sigilo básico: cono/zona de detección, alerta ("¡Alerta!") y captura ("Has sido descubierto.")
- **[COMPLETADO]** Sistema de checkpoints (Inicio, Huita, Conversación Secreta)
- **[COMPLETADO]** HUD mínimo con objetivos dinámicos, notificaciones y pantalla de fin de Alpha
- **[COMPLETADO]** Menú Principal navegable (Jugar Nivel 1, Prototipo Barca, Salir)
- **[COMPLETADO]** Core Loop completo e intencional demostrado
- **[COMPLETADO]** Prototipo independiente de la Barca (`BoatPrototype.tscn`) con aceleración por remo (Shift)

---

## Archivos Creados / Modificados

### Configuración
- `project.godot` (Configuración de resolución 1280x720, escena principal e Input Map)

### Scripts (`scripts/`)
- `scripts/pasco.gd` (Control del protagonista)
- `scripts/huita.gd` (Proximidad e interacción de Huita)
- `scripts/spanish_patrol.gd` (IA de patrulla, alerta y captura)
- `scripts/level01_convoy.gd` (Flujo narrativo y checkpoints del Nivel 1)
- `scripts/dialogue_box.gd` (Gestor de cuadros de diálogo)
- `scripts/hud.gd` (Gestor de HUD, objetivos y fin de demo)
- `scripts/boat_prototype.gd` (Mecanica de navegación de la barca)
- `scripts/main_menu.gd` (Navegación del menú principal)

### Escenas (`scenes/`)
- `scenes/main/MainMenu.tscn`
- `scenes/levels/Level01_Convoy.tscn`
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
| Interactuar / Avanzar Diálogo | **E** o **Enter** |
| Pausa / Salir a Menú (en Barca) | **Escape (Esc)** |

---

## Pruebas Realizadas

1. **P01 - Movimiento**: Verificado movimiento en 8 direcciones con WASD y Flechas.
2. **P02 - Colisiones**: Pasco no atraviesa las rocas ni los muros límites del terreno.
3. **P03 - Carrera**: Presionar Shift incrementa la velocidad de 180 a 280 px/s.
4. **P04/P05 - Interacción Huita**: Al estar cerca de Huita se despliega `[E] Interactuar`. Al presionar `E` se abre el diálogo de 3 líneas y Pasco no se mueve hasta terminar.
5. **P06/P07/P08/P09 - Patrulla y Sigilo**: La patrulla patrulla entre (1100, 360) y (1500, 360). Entrar en su radio muestra "¡Alerta!". Si se permanece más de 1.5s, captura al jugador, muestra "Has sido descubierto" y lo reaparece en el último checkpoint. Salir a tiempo cancela la alerta.
6. **P10/P11 - Conversación Secreta**: Al acercarse a los transportadores sin ser detectado, se reproduce la conversación y se actualiza el objetivo a "Regresa al punto seguro."
7. **P12/P13 - Core Loop y Final**: Al alcanzar el punto seguro final, el HUD muestra "¡Objetivo completado!" y despliega el panel de **ALPHA 0.1 COMPLETADO** con opciones de reiniciar o volver al menú.
8. **P14 - Prototipo de Barca**: `BoatPrototype.tscn` se ejecuta desde el menú principal, permitiendo navegar en el agua con WASD, remo rápido con Shift y volver al menú con Esc.

---

## Bugs Conocidos

- Ninguno detectado durante las pruebas sintácticas e integración del prototipo Alpha.

---

## Cambios respecto al GDD v1.0

- Se utilizaron formas geométricas vectoriales y colores distintivos (placeholders) en lugar de sprites artísticos finales para enfocar la iteración de la Semana 2 en la validación técnica del gameplay.

---

## Pendientes para la Semana 3

- Implementación del Nivel 2 y Nivel 3 completos.
- Persecución final de la barca con oleaje y remolinos.
- Arte final 2D y animaciones de personajes.
- Efectos de sonido (SFX) y música ambiental.
- Adaptación final para controles táctiles de Android.
