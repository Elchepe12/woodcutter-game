# WoodCutter — Instrucciones de Setup en Godot

## 1. Abrir el proyecto
Abre Godot 4.3+, clic en "Import" y selecciona:
  C:\Users\santo\woodcutter-game\project.godot

## 2. Escena principal (Main.tscn)
Crea una escena nueva con esta jerarquía:

```
Node3D  [Main]                      → script: GameManager.gd
├── WorldLight (DirectionalLight3D) → Energy: 1.2, Shadow: ON
├── Sky (WorldEnvironment)          → Environment por defecto
├── Terrain (MeshInstance3D)        → script: WorldTerrain.gd
├── ZoneManager (Node3D)            → script: ZoneManager.gd, grupo: "zone_manager"
├── PathNetwork (Node3D)            → script: PathNetwork.gd
├── SellZone (Area3D)               → script: SellZone.gd, posición: (0,0,0)
│   ├── CollisionShape3D            → BoxShape3D: 6x2x6
│   └── Label3D                     → posición: (0,2,0)
├── Shop (Area3D)                   → script: Shop.gd, posición: (5,0,0)
│   ├── CollisionShape3D            → BoxShape3D: 4x2x4
│   └── Label3D                     → posición: (0,2,0)
└── Player (CharacterBody3D)        → script: Player.gd, grupos: "player"
	├── CollisionShape3D            → CapsuleShape3D: r=0.5, h=1.8
	├── MeshInstance3D              → CapsuleMesh (cuerpo visual, opcional)
	└── Head (Node3D)               → posición: (0, 0.7, 0)
		├── Camera3D                → script: CameraShake.gd, grupo: "player_camera"
		│   └── RayCast3D           → target: (0,0,-3), enabled: ON
		└── WoodCutter (Node3D)     → script: WoodCutter.gd
			└── (usa el RayCast del padre)

## 3. Escena árbol (WoodTree.tscn)
Crea una escena nueva — los modelos .glb y la colisión se añaden AUTOMÁTICAMENTE por código:

```
StaticBody3D                        → script: Wood.gd, grupo: "wood"
└── CutEffect (Node)                → script: CutEffect.gd
	├── ChipParticles (GPUParticles3D)
	├── FallParticles (GPUParticles3D)
	├── CutSound (AudioStreamPlayer3D)  → arrastra tu .wav de hacha
	└── FallSound (AudioStreamPlayer3D) → arrastra tu .wav de caída

NOTA: NO necesitas añadir MeshInstance3D ni CollisionShape3D manualmente.
Wood.gd carga el .glb correcto automáticamente según wood_type.

## 4. Escena HUD (HUD.tscn)
Crea una escena nueva:

```
CanvasLayer                         → script: HUD.gd, grupo: "hud"
├── CuttingBar (ProgressBar)        → ancho: 300, anclaje: bottom center
├── Crosshair (Label)               → texto: "+", anclaje: center
├── ZoneLabel (Label)               → font_size: 28, anclaje: top center
├── SellResult (Label)              → font_size: 32, color: amarillo
├── SellPrompt (PanelContainer)     → anclaje: bottom center
│   └── Label
├── PanelLeft (PanelContainer)      → anclaje: top left
│   └── VBox (VBoxContainer)
│       ├── CoinsLabel (Label)
│       ├── CapacityLabel (Label)
│       └── InventoryList (VBoxContainer)
└── PanelRight (PanelContainer)     → anclaje: top right
	└── VBox (VBoxContainer)
		├── AxeLabel (Label)
		└── VehicleLabel (Label)

## 5. Escena ShopUI (ShopUI.tscn)

```
CanvasLayer                         → script: ShopUI.gd
└── MainPanel (PanelContainer)      → tamaño: 500x420, anclaje: center
	└── VBoxContainer
		├── Label                   → texto: "TIENDA DE MEJORAS"
		├── CoinsDisplay (Label)
		├── TabContainer
		│   ├── Hachas (VBoxContainer)
		│   └── Vehículos (VBoxContainer)
		└── CloseBtn (Button)       → texto: "Cerrar"

## 6. Añadir HUD a la escena principal
Instancia HUD.tscn como hijo de Main.

## 7. Assets de árboles (opcional pero recomendado)
Descarga gratis: https://hooray4brains.itch.io/free-forest-nature-pack
Extrae en: res://assets/trees/
Luego arrastra los .glb al ForestRenderer en el Inspector de cada zona.

## Controles
- WASD        → Moverse
- Ratón       → Mirar
- Clic izq    → Cortar árbol
- F           → Vender (en zona de venta)
- E           → Entrar tienda
- Espacio     → Saltar
- Esc         → Liberar ratón
