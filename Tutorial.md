# Checkers in Unity — Guided Tutorial Log

This document is an ongoing record of the guided build of a 3D isometric checkers game in Unity, following the blueprint in `README.md`. Each phase contains:
- The instructions Claude provided
- The user's answers to the knowledge check
- Corrections and expanded answers

---

## Roadmap (matching README phases)

- **Phase I** — Master the Unity interface, layout, tags, scene management
- **Phase II** — GameObjects, components, and a single tile Prefab
- **Phase III** — Materials with GPU instancing
- **Phase IV** — Colliders + kinematic Rigidbodies
- **Phase V** — Lighting, baking, isometric camera framing, UI canvas scaffolding
- **Phase VI** — Animator controllers + states for pieces
- **Phase VII** — Convergence: scripts that wire it all into a playable checkers game

---

# Phase I — Unity Interface & Workflow

## Editor steps

### I.1 — Folder structure
In `Assets/`, create the following folders (right-click → Create → Folder):
- `Scripts`
- `Prefabs`
- `Materials`
- `Textures`
- `Animations`
- `UI`
- `Scenes` (already exists)

Move existing `Test Script.cs` into `Assets/Scripts/`. Move any existing materials into `Assets/Materials/`.

### I.2 — Rename the scene
In `Assets/Scenes/`, rename `SampleScene.unity` to `MainScene` (select, press `F2`). Allow Unity to update references.

### I.3 — Save a custom layout
Arrange panels:
- Hierarchy left
- Scene and Game views centered, tabbed
- Inspector right
- Project bottom-left
- Console bottom-right

Save via `Window → Layouts → Save Layout…` as `Checkers`.

### I.4 — Isometric (orthographic) camera
Select `Main Camera`:
- Camera component → **Projection: Orthographic**
- **Size: 6**
- Transform Position: `(3.5, 10, -2.5)`
- Transform Rotation: `(60, 45, 0)`

This produces the classic isometric angle (60° down on X, 45° around Y).

### I.5 — Tags
Add these via Tag Manager (Tag dropdown → Add Tag…):
- `BoardTile`
- `CheckerPiece`
- `KingPiece`
- `UI_Overlay`
- `Camera_Isometric`

Assign `Camera_Isometric` to the `Main Camera`.

### I.6 — Save
`File → Save` and `File → Save Project`.

## Knowledge check

### Q1 — Window vs. View vs. Editor
**Q:** Which category does the Inspector fall into, and which category does the Scene fall into? Why does the distinction matter?

**User's answer:**
> The Inspector falls into the Window category, and the Scene falls into the View category. The distinction matters because of the different roles that they have; the Inspector is used to delve deeper into the various specifications of a selected game object whilst the Scene View is to look at how the various game object components work together to produce a part or whole of a game.

**Correction / expansion:**
- Classifications correct: Inspector = Window, Scene = View.
- The third category — **Editors** — is worth knowing: specialized tool contexts you *enter modally*, like Prefab Mode, the Animator window, the Sprite Editor, and Shader Graph. They're not just panels; they change the active editing context.
- The Inspector shows properties of *one selected thing at a time*. The Scene View shows the **spatial composition** of the entire scene — the 3D world you can navigate. Game View, by contrast, shows what the player would see through a camera.

### Q2 — Hierarchy vs. Project deletion
**Q:** If you delete a Cube from the Hierarchy, is the Cube's mesh still on disk? What about deleting a material from the Project window — does it affect tiles already using it?

**User's answer:**
> Deleting a Cube in the Hierarchy would remove the reference to the mesh that was on it but would still leave it on disk since the mesh is an imported file. Deleting a material from the Project window would affect the tile that is using it by just removing the material's presence in the scene and game view.

**Correction / expansion:**
- *Conclusion right, reasoning wrong on the Cube.* Unity's primitive Cube is **not an imported file** — it's a **built-in mesh** that ships with the engine. When you create a Cube via `GameObject → 3D Object → Cube`, no asset gets added to `Assets/`; the GameObject just *references* the engine's built-in mesh. Deleting the GameObject removes the reference only.
- *Material deletion is more dramatic than "just removing presence":* any object that referenced the material drops to a **null / missing material state** and renders **bright magenta (pink)** in both Scene and Game view. This is Unity's intentional visual signal that something is broken — you can't miss it. It's not a graceful fallback; it's a "fix me" warning.
- General principle: **Hierarchy = scene-level instances** (transient, scene-bound), **Project = on-disk assets** (persistent, referenced by instances). Deleting an instance never affects the asset. Deleting an asset breaks every instance that referenced it.

### Q3 — Why tags?
**Q:** What problem do tags solve at runtime that naming GameObjects (e.g. `Tile_3_4`) wouldn't solve as easily?

**User's answer:**
> Tags generalise to specific game objects. Since our grid will consist of a number of tiles that are essentially just copies of the same tile, it makes sense to have a general identifier for any one of them which is what a tag is. If we were to enumerate tiles by their positions like "Tile_3_4" that would create unnecessary overhead and be onerous to manage.

**Correction / expansion:**
- Right intuition. Sharpen: the concrete benefit is the **runtime API**.
  - `GameObject.FindGameObjectsWithTag("BoardTile")` returns every tile in the scene in one call.
  - `hit.collider.CompareTag("CheckerPiece")` is the standard pattern after a raycast — type-safe, fast, no string parsing.
- Tags decouple **category** from **identity**: a tile can still be *named* `Tile_3_4` for debugging readability, while its *tag* `BoardTile` is what code branches on. Names can change without breaking logic; tags are the stable contract.
- Parsing names like `"Tile_3_4".Split('_')` works but is **string-fragile** — one rename, one typo, and silent breakage. Tags are validated by Unity at edit time.

### Q4 — Why orthographic for isometric?
**Q:** What would go wrong visually if we used a perspective camera at the same angle?

**User's answer:**
> It would distort how the board looks and the positioning of the different pieces.

**Correction / expansion:**
- Correct, but the precise mechanism is worth knowing. A **perspective camera applies foreshortening** — objects further from the camera appear smaller (the standard depth-divide step in the rendering pipeline).
- On a tilted board, the *far* row of tiles would render smaller on screen than the *near* row, even though they're identical in world space. The diagonals would no longer be parallel; the grid wouldn't read as a uniform 8×8.
- **Orthographic projection skips the depth divide entirely**, so a tile at world distance 5 looks the same size on screen as a tile at world distance 15. This is what makes the iso grid look stable and readable.

---

## End of Phase I
Foundations laid: project organized, scene named, layout saved, camera set to orthographic isometric, tags created. Ready for Phase II — building the reusable tile Prefab and instantiating the 8×8 grid.

---

# Phase II — GameObjects, Components & the Tile Prefab

## Concepts (primer)

- **GameObject** — empty container. Does nothing on its own.
- **Component** — behavior or data attached to a GameObject (Transform, MeshFilter, MeshRenderer, BoxCollider, custom scripts). A GameObject is the sum of its components.
- **Prefab** — a saved GameObject configuration stored as an asset on disk. Scene instances reference the prefab; editing the prefab updates every instance.
- **MonoBehaviour** — base class your scripts inherit from to become attachable components and receive Unity lifecycle calls (`Awake`, `Start`, `Update`, etc.).

## Editor steps

### II.1 — Rename existing material
Rename `Tile_Dark` → `Mat_Tile_Dark` to match the README's naming convention. (`Mat_Tile_Light` and the alternation come in Phase III.)

### II.2 — Build the tile in the scene
Delete leftovers from the earlier setup (`Tile_0_0`, `Board`, etc.).
1. Hierarchy → right-click → **3D Object → Cube**, rename `Tile`.
2. Inspector → Transform gear → **Reset**.
3. Set Scale to `(1, 0.1, 1)`.
4. Drag `Mat_Tile_Dark` onto the cube.
5. Set the Tag dropdown at the top of the Inspector to **BoardTile**.

### II.3 — Save as Prefab
1. Drag the `Tile` GameObject from Hierarchy → `Assets/Prefabs/`.
2. The instance turns blue (now a prefab instance).
3. Delete the instance from the Hierarchy. The prefab asset stays.

### II.4 — Try Prefab Mode
Double-click `Tile.prefab` to enter the modal Prefab editing context. Breadcrumb at top: `Scenes/MainScene > Tile`. Click `<` to exit.

### II.5 — Create scene parents
1. Empty GameObject `BoardRoot`. Reset transform.
2. Empty GameObject `GameManager`. Reset transform.

### II.6 — `BoardGenerator.cs`
Created at `Assets/Scripts/BoardGenerator.cs`:

```csharp
using UnityEngine;

public class BoardGenerator : MonoBehaviour
{
    [SerializeField] private GameObject tilePrefab;
    [SerializeField] private Transform boardRoot;
    [SerializeField] private int boardSize = 8;
    [SerializeField] private float tileSpacing = 1f;

    void Start()
    {
        GenerateBoard();
    }

    void GenerateBoard()
    {
        for (int x = 0; x < boardSize; x++)
        {
            for (int z = 0; z < boardSize; z++)
            {
                Vector3 position = new Vector3(x * tileSpacing, 0f, z * tileSpacing);
                GameObject tile = Instantiate(tilePrefab, position, Quaternion.identity, boardRoot);
                tile.name = $"Tile_{x}_{z}";
            }
        }
    }
}
```

Key concepts:
- `: MonoBehaviour` — makes the class attachable and gives it Unity lifecycle hooks.
- `[SerializeField] private` — exposes a field to the Inspector while keeping it inaccessible to other scripts (encapsulation).
- `Start()` — called once before the first frame. Good place for one-shot setup.
- `Instantiate(prefab, position, rotation, parent)` — spawns a clone, returns its `GameObject` reference so we can operate on the new instance immediately.

### II.7 — Wire up
On `GameManager`: Add Component → `Board Generator`. Drag `Tile.prefab` into Tile Prefab; drag `BoardRoot` into Board Root.

### II.8 — Press Play
8×8 grid spawns under `BoardRoot`. **Reminder:** edits made in Play mode are discarded on stop.

## Knowledge check

### Q1 — Prefab vs instance
**Q:** Does changing an instance affect the prefab? What about editing the prefab — does it propagate to all instances?

**User's answer:**
> No, it will not affect the prefab if I change something on the tile instance in the scene. This is because the prefab already has defaults baked in and don't take changes that affect it into consideration after the fact. If we were to modify the prefab itself then this would affect the tiles we see on the board (all 64 instances of them).

**Correction / expansion:**
- Right idea. Subtlety: changes on an instance become **overrides** (shown bold with a blue margin line in the Inspector). They shadow the prefab's value *for that property on that instance*. Other instances still update when the prefab changes; the overridden instance keeps its override.
- Right-click an overridden property → **Revert** to drop the override and go back to inheriting from the prefab.

### Q2 — `[SerializeField]` vs `public`
**Q:** Both expose to Inspector. Why prefer `[SerializeField] private`? What does `public` give you that `[SerializeField] private` doesn't?

**User's answer:**
> public would allow our code to be modified from other scripts which we wouldn't want in this case. The issue with using only private is that it removes the fields from the inspector that is useful for the purposes. Serialize field gives us the best of both worlds: allowing use to use a private field with the functionality of modifying its values for realtime testing.

**Correction / expansion:**
- Textbook-correct. The principle is **encapsulation**: minimize the surface area exposed to other code. `public` = visible to all scripts *and* the Inspector. `[SerializeField] private` = visible to the Inspector only; other scripts can't touch the field. Use `public` only when external code *needs* access.

### Q3 — `Instantiate` return value
**Q:** Why is it useful that `Instantiate` *returns* the new GameObject?

**User's answer:**
> Because we want copies of the tiles themselves, and otherwise we would just modifying the existing tiles in place which is not want we want to create a board.

**Correction / expansion:**
- The user answered "why use Instantiate at all" rather than "why does it *return* the GameObject."
- The actual answer: returning a reference to the new clone lets us **immediately operate on that specific instance** — rename it (`tile.name = $"Tile_{x}_{z}"`), reposition, attach data, store in an array, etc. Without the return value, we'd have to *find* the new instance afterwards (search by name, walk children), which is slow and brittle when spawning many objects.

### Q4 — Reset Transform before prefabbing
**Q:** What kind of bug does that prevent later when we instantiate?

**User's answer:**
> It normalises where the values should be found. If not we wouldn't have a central point of reference and our game objects would be all over the place if we didn't do that as we proceeded.

**Correction / expansion:**
- Right intuition; the specific mechanism matters: when we call `Instantiate(prefab, position, Quaternion.identity, parent)`, Unity **overrides position and rotation** with our arguments — but **scale is inherited from the prefab**. If the prefab had non-uniform scale, hidden rotation, or accidental local offsets, every one of the 64 instances would silently inherit them.
- Resetting the Transform before saving guarantees a known canonical state, so any weirdness later is something *we* introduced, not leftover from prefab creation.

## Phase II — Editor issues encountered & fixes

**Lost board in Scene view (panning with Q):** select any object (e.g., `BoardRoot`) in the Hierarchy, hover cursor over the Scene view, press **F** to frame-select. Or double-click the GameObject in the Hierarchy. Useful navigation: `Alt + LMB` orbits, `RMB + WASD` flies, top-right Scene Gizmo snaps to axes.

**Game view shows perspective after toggling projection:** verify in *edit mode* (not Play) that Main Camera Projection is set to Orthographic (Size 6). Edits made during Play mode revert on stop. Use Hierarchy search `t:Camera` to confirm only one camera is in the scene. Check the URP Camera Stack on the Camera component for stray Overlay cameras. Save with `Cmd+S` and `File → Save Project`.

## End of Phase II
Tile prefab built, `BoardGenerator` script spawns the 8×8 grid into `BoardRoot` at runtime. Ready for Phase III — proper materials, alternating light/dark colors, and GPU instancing.

---

# Phase III — Materials & GPU Instancing

## Concepts (primer)
- **Shader** — GPU program that decides how a surface is drawn (lighting, color, reflectivity).
- **Material** — data fed to a shader. Same shader + different materials = different appearances. URP default: `Universal Render Pipeline/Lit`.
- **GPU Instancing** — optimization that batches identical mesh+material draws into a single draw call. Requires same mesh, same material asset (via `sharedMaterial`), and the material's "Enable GPU Instancing" checkbox.

## Editor steps

### III.1 — `Mat_Tile_Light`
Right-click in `Assets/Materials/` → Create → Material. Settings:
- Shader: `Universal Render Pipeline/Lit`
- Surface Type: Opaque
- Base Map color: `(235, 220, 180)` (cream)
- Smoothness: `0.15`, Metallic: `0`
- **Advanced Options → Enable GPU Instancing ✅**

### III.2 — `Mat_Tile_Dark`
Same shader. Base Map `(90, 60, 35)` (dark walnut). Smoothness `0.15`, Metallic `0`. GPU Instancing ✅.

### III.3 — Piece materials

| Material | Base Map RGB | Smoothness | Metallic | GPU Instancing |
| --- | --- | --- | --- | --- |
| `Mat_Piece_White` | `(240, 235, 220)` | `0.35` | `0` | ✅ |
| `Mat_Piece_Black` | `(30, 30, 30)` | `0.35` | `0` | ✅ |
| `Mat_Piece_King` | `(200, 170, 60)` | `0.7` | `0.5` | ✅ |

Used in later phases when piece prefabs are built; created now to match the README.

### III.4 — Updated `BoardGenerator.cs`

Added two `[SerializeField] private Material` fields and the alternation logic:

```csharp
[SerializeField] private Material lightTileMaterial;
[SerializeField] private Material darkTileMaterial;
// ...
bool isDark = (x + z) % 2 == 0;
Material tileMaterial = isDark ? darkTileMaterial : lightTileMaterial;
tile.GetComponent<MeshRenderer>().sharedMaterial = tileMaterial;
```

Also applied a Roslyn style hint (target-typed `new()` instead of `new Vector3(...)`).

### III.5 — Wire up
On `GameManager` → Board Generator: drag `Mat_Tile_Light` and `Mat_Tile_Dark` into the new slots.

### III.6 — Verify
Play. Tile `(0,0)` is dark; alternation produces a real checkerboard.

### III.7 — Frame Debugger sanity check
`Window → Analysis → Frame Debugger → Enable`. Look for `Draw Mesh (instanced)` calls — should be ~2 (one per material) instead of 64.

## Knowledge check

### Q1 — Shader vs Material
**User's answer:**
> A shader is a program that runs on the GPU that dictates how a surface looks based on lighting, colouring, patterns, etc, and a material is an input for a shader which can result in a different surface outward looks for different materials under the same shader.

**Verdict:** Correct. Same shader + different materials = different appearances (e.g., `Mat_Tile_Light` vs `Mat_Tile_Dark`).

### Q2 — GPU instancing prerequisites
**User's answer:**
> My intuition tells me that we need a computer with a GPU or else it will divert to using a CPU. I'm not entirely sure what the answer to this should be to be honest.

**Correction / expansion:**
Hardware isn't the question — any machine running Unity has a capable GPU. The software-side prerequisites:
1. Same mesh on every renderer.
2. Same material **asset** on every renderer (assigned via `sharedMaterial`, not `material`).
3. Material's shader supports instancing **and** the "Enable GPU Instancing" checkbox is ticked.
4. (Bonus) No per-object data that fragments instancing groups (e.g., differing baked lightmaps).

### Q3 — `material` vs `sharedMaterial`
**User's answer:**
> Because the first option creates a copy rather than operating on the tiles themselves; the second option can affect other parts of our game as well if you ever change the colour scheme, say in the case that Color.red is declared globally then used in various parts of the game.

**Correction / expansion:**
- The "globally declared `Color.red`" framing isn't right — `Color.red` is a constant. The hazard is the **shared material asset**, not the color value.
- `.material.color = ...` → reading `.material` *clones* the material asset into a per-renderer copy, then mutates the copy. Only that one tile changes. Slower, breaks instancing for that one renderer, but isolated.
- `.sharedMaterial.color = ...` → mutates the **asset itself**. Every renderer using it changes. In the editor, the change **persists into edit mode after Play stops** — the asset is genuinely modified on disk until manually reverted. Famous footgun.

Rule of thumb: assigning a *reference* via `sharedMaterial = mat` is fine (what we did). Mutating *properties* on `sharedMaterial` is the dangerous part.

### Q4 — Alternation logic
**User's answer:**
> The condition (x % 2 == 0) would produce a board without alternating colors, we would get instead essentially our tiles forming lines are every even position since all those tiles would get updated in those positions.

**Correction / expansion:**
Right structure (stripes), let's nail the orientation: `(x % 2 == 0)` ignores `z`, so every tile in a given column gets the same answer. Result: **entire columns become one color** — stripes parallel to the z-axis, not a checkerboard. The `(x + z)` sum is what couples both axes so the value flips with each step in *either* direction.

## End of Phase III
Materials defined and registered, GPU instancing enabled, alternating checkerboard rendering. Ready for Phase IV — colliders and kinematic Rigidbodies, which makes the board interactive.

---

# Phase IV — Colliders & Kinematic Rigidbodies

## Concepts (primer)
- **Collider** — physics shape used for contacts/raycasts; doesn't have to match the visual mesh.
- **Trigger collider** — `Is Trigger ✅`. Detects overlaps and raycasts but doesn't physically push. For "this tile was clicked" without tiles bumping pieces.
- **Rigidbody** — makes a GameObject participate in physics (gravity, forces, velocity).
- **Kinematic Rigidbody** — Rigidbody that ignores forces and gravity. Moved via `transform.position`. Still registers with the physics system for collision/trigger detection.
- **Discrete collision detection** — checks once per physics tick. Cheap. Fine for slow, turn-based motion. Continuous is only needed to prevent tunneling for fast-moving objects.

## Editor steps

### IV.1 — Tile collider as trigger
Open `Tile.prefab` in Prefab Mode. Box Collider → tick **Is Trigger ✅**. Center `(0,0,0)`, Size `(1,1,1)` — local-space, scales with the Transform. Exit Prefab Mode (auto-saves).

### IV.2 — Hierarchy reorganization
- Rename `BoardRoot` → `Board_Colliders` (Unity tracks references by ID, so the BoardGenerator slot stays valid).
- Create empty `Active_Pieces` (sibling). Reset Transform.

### IV.3 — `Piece_White` prefab
1. 3D Object → Cylinder, rename `Piece_White`.
2. Reset Transform, set Scale to `(0.7, 0.15, 0.7)`.
3. Drag `Mat_Piece_White` onto it.
4. Tag: `CheckerPiece`.
5. Capsule Collider (auto-attached): Radius `0.45`.
6. Add Component → Rigidbody:
   - Use Gravity ❌
   - Is Kinematic ✅
   - Interpolation: Interpolate
   - Collision Detection: Discrete
7. Drag into `Assets/Prefabs/`. Delete scene instance.

### IV.4 — `Piece_Black` prefab
Duplicate `Piece_White.prefab` (`Cmd+D`), rename `Piece_Black.prefab`. Open in Prefab Mode, swap material to `Mat_Piece_Black`. Exit.

### IV.5 — Visual sanity check
Drop one of each into the scene at `(0, 0.15, 0)` and `(7, 0.15, 7)` (or `Y = 0.20` if they clip into the tile). Press Play, confirm: no falling, no nudging when poked. Stop, delete the manual instances — Phase VII spawns them via script.

## Knowledge check

### Q1 — Kinematic Rigidbody
**User's answer:**
> The kinetic rigidbody enables our pieces to have a feel like how real checkers pieces would behave in the real world in terms of their physics while neglecting forces and gravity which is unecessary for our purposes.

**Correction:**
- "Real-world physics feel" is the opposite of kinematic. Kinematic *opts out* of the physics simulation while staying **registered** with the physics system.
- Two concrete benefits over a plain Transform:
  1. **Trigger events fire** — `OnTriggerEnter/Exit` only fire when at least one of the colliding objects has a Rigidbody.
  2. **Cheap movement** — colliders without Rigidbodies are treated as **static**; moving them rebuilds Unity's static physics tree every frame (expensive). A Rigidbody (kinematic or not) tells Unity "this moves," and the engine optimizes accordingly.

### Q2 — Trigger vs solid
**User's answer:**
> If is Trigger was unchecked it may be the case that a given piece could fall through the board since no detection would be available and this would result in undesirable behaviour for our game.

**Correction:**
- Backwards. A non-trigger collider is **solid** — pieces would *not* fall through, they'd physically collide.
- The real reason for trigger: detect raycast hits and overlaps **without** generating physical collision response. With a non-trigger tile, a piece's CapsuleCollider intersecting it would fire `OnCollisionEnter`, generate contact points, and (if pieces were non-kinematic) push them around. Trigger = "I'm here to be detected, not to bump anything."

### Q3 — Discrete collision detection
**User's answer:**
> Discrete collisions detections only checks for collisions once per physics frame and this makes the operations computationally cheap. Moreover, in a game like checkers we only need a simple setup such as this because it is not a particular fastpaced for demnding game with requires more.

**Verdict:** Correct. Continuous is needed only to prevent **tunneling** — a fast object moving farther than the thickness of a collider in one physics tick. Checkers pieces never approach that speed.

### Q4 — CapsuleCollider on Cylinder
**User's answer:**
> The capsule collider is a good enough shape because checkers only really requires a means to verify when a piece is captured. the actual physics of it doesn't come into play so it is sufficient for all intents and purposes. The Box collider but flattened would also suffice.

**Verdict:** Right call. At Scale `(0.7, 0.15, 0.7)` the capsule's height is so small relative to its radius that it's effectively a flat disc — perfect silhouette for top-down click detection. A flat BoxCollider is a valid alternative; some devs prefer it because boxes are the cheapest collider shape.

## End of Phase IV
Tiles are clickable triggers; piece prefabs configured with kinematic Rigidbodies. Ready for Phase V — lighting, baking, and the UI canvas scaffold.

---

# Phase V — Lighting & UI Canvas Scaffold

## Concepts (primer)
- **Directional Light** — simulates the sun. Parallel rays, infinite distance. Defined by *rotation*, not position.
- **Point Light** — radiates outward with falloff over distance.
- **Area Light** — soft rectangular emitter (bake-only in Built-in pipeline).
- **Lightmap baking** — precomputes lighting/shadows for static, edit-time objects into a texture; can't apply to runtime-spawned objects.
- **Canvas** — root container for all UI; Render Mode dictates where it draws.
- **EventSystem** — auto-created singleton that routes input (clicks, taps, keyboard) to UI elements.
- **TextMeshPro (TMP)** — modern SDF-font text renderer. Sharp at any zoom.

## Editor steps

### V.1 — Directional Light
- Rotation `(60, 45, 0)`, color `(255, 244, 220)`, Mode Realtime, Intensity `1.2`, Indirect Multiplier `1`.
- Shadow Type: Soft Shadows. Strength `0.7`.

### V.2 — Environment lighting
`Window → Rendering → Lighting → Environment`:
- Skybox Material: default URP skybox (or None).
- Environment Lighting → Source: Skybox, Intensity `1`.
- Environment Reflections → Intensity `0.7`.

If shadows look harsh, in `Edit → Project Settings → Quality` open the active URP Asset and check Shadows → Soft Shadows + Cascade Count 2–4.

### V.3 — Why we skip baking
Lightmap baking requires **static, edit-time** objects. Our tiles don't exist until `BoardGenerator.Start()` runs at runtime. There's no edit-time geometry to bake. Workarounds (out of scope): pre-place tiles in editor and mark Static, or use Light Probes for runtime-spawned objects.
For 64 simple objects, realtime lighting is plenty performant.

### V.4 — Canvas
`UI → Canvas` (also creates `EventSystem`). If TMP Essentials prompt appears, import.
- Render Mode: Screen Space - Overlay.
- Canvas Scaler: UI Scale Mode = Scale With Screen Size; Reference Resolution `1920×1080`; Match `0.5`.
- Tag: `UI_Overlay`.

### V.5 — Turn indicator
Right-click Canvas → UI → Text - TextMeshPro. Rename `TurnIndicator`.
- Anchor: top-center (Shift+Alt + click preset).
- Pos Y `-50`. Width `400`, Height `60`.
- Text `Turn: White`. Font Size `42`. Center, Middle alignment.

### V.6 — Reset button
Right-click Canvas → UI → Button - TextMeshPro. Rename `ResetButton`.
- Anchor: top-right.
- Pos X `-100`, Pos Y `-50`. Width `160`, Height `50`.
- Inner Text (TMP) child: text `Reset`, font size `28`.

OnClick wiring deferred to Phase VII.

### V.7 — Verify
Press Play: lit board with diagonal shadows, "Turn: White" at top, hoverable Reset button at top-right.

## Knowledge check

### Q1 — Directional light
**User's answer:**
> Directional lighting is more apt for the isometric perspective that we are going for. Point lighting wouldn't work well in this case because it would draw attention to specific parts of the board which is bad from a design perspective because it hints that there is something special about those parts which is not true. The same would be true of area lighting.

**Correction / expansion:**
- Right design-level conclusion. The deeper technical reason: directional lights cast **parallel rays from infinitely far away** — no distance falloff, every tile receives equal intensity. Defined entirely by rotation; position is irrelevant.
- Point lights have **radial falloff** — tiles closer to the light are brighter than tiles further away, so the lighting visibly slopes across the board.
- So: directional = parallel + uniform; point = radial + falloff.

### Q2 — Baking limitation
**User's answer:**
> Given that there are no tile objects that would exist at edit time, using baked lights here would create a mismatch in the sense of that we would be trying to bake light on a non-existent gameobject. Thus the issue is that our current setup doesn't have the requisite static objects in place beforehand for baked lighting to even apply.

**Verdict:** Correct, captured the constraint precisely.

### Q3 — Canvas Render Modes
**User's answer:**
> I would say that Screen Space camera might be useful in the case where we need the camera to track movement like in a first person shooter where in this case we would be tracking the player as the treks through the game. Alternatively, World space is probably useful for a platformer game where we would need wider and more expansive lay of the land, than say in this checkers game we're trying to make now.

**Correction:**
- **Screen Space - Overlay** — drawn on top of everything in screen pixels. HUD/menus. Camera-independent.
- **Screen Space - Camera** — rendered at a specified distance in front of a chosen camera. Still 2D-locked to screen, but **3D objects can occlude the UI** and post-processing affects it. Used when UI needs to interact with 3D depth, *not* for "tracking the player."
- **World Space** — UI exists *in the 3D world* as a flat plane. Used for damage numbers floating above enemies, in-world signs, VR menus, name labels — *not* for a platformer's HUD (you'd still use Overlay there).

### Q4 — EventSystem
**User's answer:**
> The eventsystem attached to the canvas directs where our inputs should go. Without it the UI elemnts generated by the canvas can do nothing in terms of allowing the player to interact with the game.

**Verdict:** Correct.

## Phase V — Editor issues encountered & fixes

**Game view shows bird's-eye while Scene view shows iso.** Scene view ≠ Game view; the Scene camera is independent from `Main Camera`. In edit mode, verify `Main Camera` Position `(3.5, 10, -2.5)`, Rotation `(60, 45, 0)`, Projection Orthographic, Size `6`. Use Hierarchy filter `t:Camera` to confirm only one camera. Don't change camera in Play mode (changes revert). Save scene with `Cmd+S`.

**Couldn't drag materials onto piece prefabs.** Materials go on the **Mesh Renderer**, not the Capsule Collider. Procedure: double-click the prefab to enter Prefab Mode, then either (a) drag the material onto the visible cylinder in the Scene view, or (b) Inspector → Mesh Renderer → Materials array → drop into Element 0. Dragging onto the prefab asset in the Project window does nothing because Unity doesn't know which renderer inside it you mean.

## End of Phase V
Lighting set to iso-friendly directional with soft shadows; UI scaffold (Canvas, EventSystem, turn indicator, reset button) in place. Ready for Phase VI — Animator controllers and state machines for piece animations.

---

# Phase VI — Scripting Architecture (raycasts, layers, debugging)

After README2.md was added, the curriculum was restructured. Phase VI is now scripting fundamentals (README2 §VIII), Phase VII is Animator (was originally Phase VI). Subsequent phases shift accordingly.

## Concepts (primer)

### MonoBehaviour lifecycle
- `Awake()` — once, at object creation. Self-init only (don't reach out to other objects).
- `OnEnable()` — every time enabled; subscribe to events here.
- `Start()` — once, before first frame, after all `Awake()` in the scene. Safe to look up other scene-load objects.
- `Update()` — every frame. Input polling, frame-tied logic.
- `FixedUpdate()` — every physics tick. Forces, physics-tied work.
- `OnDestroy()` — unsubscribe from events.

### Layers (vs Tags)
- **Tag** — single string label for **code logic identity** (`CompareTag(...)`). One per GameObject.
- **Layer** — numeric channel (0–31) for **physics & rendering** filtering. One per GameObject. Orthogonal to tags.

### Physics.Raycast
`Physics.Raycast(ray, out hit, maxDistance, layerMask)` — shoots an invisible line and returns the first collider hit on the masked layers. The `layerMask` is a 32-bit integer; bit *N* set = layer *N* eligible.

### Collision matrix vs raycast filtering
- **Collision matrix** — governs `OnCollisionEnter`/`OnTriggerEnter` callbacks between layers.
- **layerMask parameter** — governs which layers a single raycast can hit.
- Independent systems. Unchecking the matrix doesn't break raycasts.

## Editor steps

### VI.1 — Active Input Handling
`Edit → Project Settings → Player → Other Settings → Active Input Handling` → **Both**. Restart editor.

### VI.2 — Custom Layers
Layer 6 = `Board`, Layer 7 = `Pieces` (built-in `UI` layer 5 and `Ignore Raycast` layer 2 stay as-is).

### VI.3 — Layer assignments
Tile prefab → Layer Board. Piece prefabs → Layer Pieces. Apply to children when prompted.

### VI.4 — Collision Matrix
`Edit → Project Settings → Physics → Layer Collision Matrix` → uncheck `Pieces ↔ Board`. Pieces stop firing collision callbacks against tiles; raycasts still hit both.

### VI.5 — `SelectionProbe.cs`
Created at `Assets/Scripts/SelectionProbe.cs`:

```csharp
using UnityEngine;

public class SelectionProbe : MonoBehaviour
{
    [SerializeField] private Camera sceneCamera;
    [SerializeField] private LayerMask interactableLayers;
    [SerializeField] private float maxRayDistance = 100f;

    void Update()
    {
        if (sceneCamera == null) return;

        Ray ray = sceneCamera.ScreenPointToRay(Input.mousePosition);
        Debug.DrawRay(ray.origin, ray.direction * maxRayDistance, Color.yellow);

        if (Input.GetMouseButtonDown(0))
        {
            if (Physics.Raycast(ray, out RaycastHit hit, maxRayDistance, interactableLayers))
            {
                string layerName = LayerMask.LayerToName(hit.collider.gameObject.layer);
                Debug.Log($"Clicked: {hit.collider.name} | Tag: {hit.collider.tag} | Layer: {layerName}");
            }
            else
            {
                Debug.Log("Clicked: nothing on the interactable layers");
            }
        }
    }
}
```

Notes:
- `[SerializeField] Camera sceneCamera` — avoids `Camera.main` (which requires the `MainCamera` tag; ours is `Camera_Isometric`) and avoids a per-frame tag lookup.
- `Debug.DrawRay` — yellow line in Scene view during Play, with Gizmos enabled.
- `out RaycastHit hit` — `out` means the function fills it in.

### VI.6 — Wire up
GameManager → Add Component → Selection Probe. Drag `Main Camera` into Scene Camera. Tick `Board` + `Pieces` in Interactable Layers. Max Ray Distance `100`.

### VI.7 — Test
Press Play. Click tiles. Console shows `Clicked: Tile_3_5 | Tag: BoardTile | Layer: Board`. With Scene view + Gizmos on, watch the yellow ray follow the cursor. Click off-board → "nothing on the interactable layers".

## Knowledge check

### Q1 — Awake vs Start
**User's answer:**
> It should grab the reference in Start() because in our case we're generating the game tiles via a script to initialises all of them and this could cause some issues like grabing a reference to an object that may not exist at the point when Awake() is called. Start() is better because the game objects have been initialised and the game has not yet started, so it resolves many of the issues that may crop up with Awake().

**Correction / expansion:**
- Right answer (Start), partially right reasoning.
- Precise rule: **all `Awake()` calls in the scene run before any `Start()`**. So in `Start()`, you can safely look up scene-load objects.
- `Awake()` = self-init only (cache components, set defaults). Don't reach out to other objects there.
- Caveat: runtime-spawned objects (`Instantiate`) aren't guaranteed to be ready in another script's `Start()` either. For those, prefer direct refs handed out by the spawner, or events.

### Q2 — Layers vs Tags
**User's answer:**
> Tags are essentially strings that we can reference in the code if we want to modify a game object in some way. On the other hand, Layers, as the name suggests, allow us to delinate various components and their subcomponents so we can target the specific parts we want. This is computataionally more efficient and makes it easier to debug in the long run.

**Correction / expansion:**
- **Tag** = single-string label for **code-logic identity**. `CompareTag("BoardTile")` — "is this a tile?"
- **Layer** = numeric channel for **physics & rendering** filtering (collision matrix, raycast layerMask, camera culling).
- They're **orthogonal**. A GameObject can have a `BoardTile` tag AND be on the `Board` layer simultaneously, and they're used by different systems.
- Rule of thumb: tag = behavioral question in script. Layer = physics/render question ("should this even be considered for this query?").

### Q3 — Collision matrix and raycasts
**User's answer:**
> Unchecking the box in the collision matric only disables the physics effects between the two components; it doesn't affect the lighting aspects of our setup.

**Correction:**
- Lighting is unrelated to the collision matrix.
- The matrix governs **collision/trigger callbacks** between layers (`OnCollisionEnter`, `OnTriggerEnter`).
- **Raycasts** are queries — they read which colliders intersect a line, filtered by the `layerMask` parameter you pass at the call site. The matrix doesn't gate them.
- So the matrix and raycast filtering are **independent systems**.

### Q4 — Bitmask
**User's answer:**
> 192

**Verdict:** ✅ Correct. `1 << 6 = 64`, `1 << 7 = 128`, `64 | 128 = 192` (binary `11000000`).

## End of Phase VI
Layers and collision matrix configured; SelectionProbe demonstrates raycast-driven click detection. Ready for Phase VII — Animator controllers and state machines.

---

# Phase VII — Animator Controllers & States

## Concepts (primer)
- **FSM** — finite state machine; system is in exactly one state at a time.
- **Animation Clip** (`.anim`) — keyframed motion data.
- **Animator Controller** (`.controller`) — the FSM asset (states, transitions, parameters).
- **Parameter types** — Bool (ongoing state), Trigger (one-shot event, auto-resets), Int/Float (rare in this project).
- **Has Exit Time** — when ON, transition fires only after source clip has played a fraction; when OFF, fires the moment conditions are true.
- **Transition Duration** — blend time. `0.15s` for snappy feedback.
- **Apply Root Motion** — when ON, animations directly move the Transform (fights script for ownership). For grid-based games like ours, leave OFF.

## Editor steps

### VII.1 — Create `PieceAnimator` controller
`Assets/Animations/` → Create → Animator Controller → name `PieceAnimator`.

### VII.2 — Attach Animator to piece prefabs
Both `Piece_White.prefab` and `Piece_Black.prefab`: Add Component → Animator. Drag `PieceAnimator` into Controller. Apply Root Motion OFF.

### VII.3 — States
In Animator window, create five empty states: `Idle`, `Selected`, `Moving`, `Capturing`, `Promoted`. Right-click `Idle` → Set as Layer Default State.

### VII.4 — Parameters
- Bool `isSelected`
- Trigger `triggerMove`
- Trigger `triggerCapture`
- Bool `isPromoted`

### VII.5 — Transitions

| From | To | Condition | Has Exit Time | Duration |
| --- | --- | --- | --- | --- |
| Idle | Selected | `isSelected == true` | ❌ | 0.15 |
| Selected | Idle | `isSelected == false` | ❌ | 0.15 |
| Selected | Moving | `triggerMove` | ❌ | 0.15 |
| Moving | Idle | (none) | ✅ | 0.15 |
| Idle | Capturing | `triggerCapture` | ❌ | 0.05 |
| Capturing | Idle | (none) | ✅ | 0.10 |
| Idle | Promoted | `isPromoted == true` | ❌ | 0.20 |
| Selected | Promoted | `isPromoted == true` | ❌ | 0.20 |

### VII.6 — Selected scale-pulse clip
In Prefab Mode for `Piece_White`: Animation window → Create → save as `Assets/Animations/Piece_Selected.anim`. Record keyframes at t=0, 0.25, 0.5 cycling Scale `(0.7, 0.15, 0.7)` → `(0.8, 0.17, 0.8)` → back. Loop Time ON. Move clip from default `Idle.Motion` to `Selected.Motion`; clear Idle's Motion.

### VII.7 — Test
Drop a piece into the scene, Play, select it, tick `isSelected` in the Animator parameter list to see the pulse.

## Knowledge check

### Q1 — Script vs Animator
**User's answer:**
> The script and animator should both track certain things such as if "this piece is selected", because it is necessary for the animator to know so that it can produce an animation and the script to know so that it can perform additional functionalities.

**Correction:**
- Wrong direction. **Script holds the source of truth.** The Animator only sees what parameters the script sets via `SetBool/SetTrigger`. It doesn't independently know anything.
- Both tracking = duplicate state that can desync. Always: one source of truth, one visual reflection.

### Q2 — Has Exit Time on/off
**User's answer:**
> we want no animations when we go back to an idle state ... we want the transition to somewhat "abrupt" so that it signals to the player that we are back in the idle state.

**Correction:**
- Right answer (off for Idle→Selected, on for Moving→Idle), but reasoning is inverted. Has Exit Time being ON does NOT make a transition abrupt — it *delays* the transition until the source clip has played for some normalized fraction.
- Real reason: `Idle → Selected` has a **condition** (`isSelected == true`) the script flips, so Exit Time is unnecessary. `Moving → Idle` has **no condition** — there's nothing for the script to flip — so Exit Time IS the firing mechanism. Without it, the FSM would be stuck in Moving forever.

### Q3 — Bool vs Trigger
**User's answer:**
> if triggerMove was a Bool instead of a trigger it should result in undesireable behaviour ... animation may not have a strong enough condition to play or overlap in some way.

**Correction:**
- Specific mechanism: **Triggers auto-reset after firing a transition; Bools stay set until script clears them.**
- If `triggerMove` were a Bool: script sets it true → Idle→Moving fires → Moving→Idle auto-exits → back in Idle but the bool is still true → Idle→Moving fires again → **infinite loop**.
- Triggers solve it because Unity clears them the instant they consume a transition.

### Q4 — Root motion
**User's answer:**
> "Root motion" is the kind of motion that would apply to the joint or humoid figures to make them appear more realistic.

**Correction:**
- Most associated with humanoids, but applies to any Animator: **root motion = animations directly move the Transform (position/rotation) as part of the clip.**
- If ON and a clip translates the cylinder, the piece would drift on the board. More critically: the script sets `transform.position` to slide a piece, and root motion would *add* its own offset on top, fighting the script for ownership.
- OFF = Transform is owned by the script. The Animator only affects properties the script doesn't manage.

## Phase VII — Editor issues encountered & fixes

**Animation window record button greyed out.** The window is contextual — needs a GameObject with Animator selected, in edit mode, with a clip active. Most common cause: exited Prefab Mode. Re-enter Prefab Mode (double-click the prefab), select the cylinder root in the Prefab Mode Hierarchy, verify clip dropdown shows the active clip, ensure not in Play mode.

**Pulse not visible in Game view.** The Animation editor previews clips directly regardless of the FSM. In Play mode, the FSM sits in Idle (no clip) until something flips `isSelected`. To see the pulse: drop a piece into the scene, Play, select it in the Hierarchy, then in the **Animator window's Parameters panel** (not the Inspector — Inspector parameter checkboxes don't exist here) tick `isSelected`. Watch the Animator window's blue progress bar move from Idle to Selected.

**Transition condition silently ignored.** The transition Inspector has a free-text label/name field near the top — typing `isSelected == true` there does nothing. The actual **Conditions** section is at the bottom with a `+` button: click `+`, pick the parameter from the dropdown, set the comparison/value. Always confirm conditions are *rows* in that bottom list, not free text.

## End of Phase VII
Animator FSM with five states, four parameters, eight transitions; one real clip (Selected pulse). Ready for Phase VIII — programmatic piece spawning and click-driven selection that flips `isSelected` for real.

---

# Phase VIII — Spawn Pieces & Click Selection

## Concepts (primer)
- **Single source of truth** — script owns "is this piece selected?"; Animator reflects it via `Piece.SetSelected(bool)`.
- **`enum`** — finite named set; `PieceColor { White, Black }`.
- **`Animator.StringToHash`** — parameter-name-to-int once; subsequent calls skip string lookup. Useful in hot paths; premature optimization in click-driven code.
- **Auto-properties** — `public int GridX { get; private set; }` = read-public, write-private.

## Editor steps & scripts

### VIII.1 — `Piece.cs`
`Assets/Scripts/Piece.cs`. Holds color, grid coordinates, isKing, exposes `SetSelected(bool)` and `Promote()` API. Uses `[RequireComponent(typeof(Animator))]` to enforce dependency.

```csharp
using UnityEngine;

public enum PieceColor { White, Black }

[RequireComponent(typeof(Animator))]
public class Piece : MonoBehaviour
{
    [SerializeField] private PieceColor color;
    [SerializeField] private Animator animator;

    public PieceColor Color => color;
    public int GridX { get; private set; }
    public int GridZ { get; private set; }
    public bool IsKing { get; private set; }

    private static readonly int IsSelectedHash = Animator.StringToHash("isSelected");
    private static readonly int IsPromotedHash = Animator.StringToHash("isPromoted");

    void Awake()
    {
        if (animator == null) animator = GetComponent<Animator>();
    }

    public void Initialize(int x, int z, PieceColor pieceColor)
    {
        GridX = x;
        GridZ = z;
        color = pieceColor;
    }

    public void SetSelected(bool selected) => animator.SetBool(IsSelectedHash, selected);
    public void Promote() { IsKing = true; animator.SetBool(IsPromotedHash, true); }
}
```

### VIII.2 — Attach `Piece` to prefabs
Both piece prefabs: Add Component → Piece. Set Color in Inspector.

### VIII.3 — `PieceSpawner.cs`
Spawns 12 white (rows 0–2) and 12 black (rows 5–7), all on dark squares (`(x + z) % 2 == 0`). Calls `piece.Initialize(x, z, color)` after `Instantiate`.

### VIII.4 — `PieceSelector.cs`
Replaces SelectionProbe. Raycasts on left-click against `Pieces` layer; toggles `isSelected` on the clicked Piece. Tracks `currentSelection` reference, deselects previous before selecting new.

> **Naming note:** the class was originally `Selection`, which collided with Unity's `UnityEditor.Selection` and broke the URP template's `ReadmeEditor.cs`. Renamed to `PieceSelector`. **Lesson:** the global namespace is shared with Unity — avoid `Selection`, `Object`, `Random`, `Camera`, `Light` etc. as class names.

### VIII.5 — Wire up
GameManager: remove SelectionProbe component. Add PieceSpawner (drag prefabs + Active_Pieces). Add PieceSelector (drag camera, tick Pieces layer mask).

### VIII.6 — Test
Play. 24 pieces spawn. Clicking a piece pulses it; clicking another swaps; clicking same toggles off; clicking empty space deselects.

## Knowledge check

### Q1 — Auto-property `{ get; private set; }`
**User's answer:**
> Because the first one allows us to access the values via getters but makes the setters private so that its values cannot be arbitrarliy mutated.

**Verdict:** Correct. The `private set` specifically protects against any external script mutating `GridX`/`GridZ` after Initialize. Read-public, write-class-only. Smallest possible write surface = encapsulation.

### Q2 — `StringToHash` performance
**User's answer:**
> in the case that a player is constantly selecting and deselecting a piece this woud create unnecessary overhead ... This matters in our situtation where the pieces are generated and not so much if we had a singular piece that would be the only choice to select, in this kind of case the optimisation would be premature.

**Correction:**
- Right intuition (call frequency matters), wrong conclusion for our case. It's actually **calls per frame** that matter, not number of pieces.
- `SetSelected` fires only on click (user-paced, ~once a second at most). For our game, the optimization is **premature** — we use it because it's the canonical Unity idiom, not because it materially helps here.
- It would genuinely matter in a hot path (per-frame `Update()` driving a continuous animation parameter).

### Q3 — Null guard in `DeselectCurrent`
**User's answer:**
> The guard is needed because ultimatly it would deselect select all the pieces when the game first starts up.

**Correction:**
- Off-target. Without the guard, on the **very first click** `currentSelection` is `null`. `currentSelection.SetSelected(false)` then throws a **NullReferenceException** and the click handler crashes. Nothing iterates over all pieces — the issue is dereferencing a null field.

### Q4 — `Initialize(x, z, color)` vs Awake
**User's answer:**
> It is simpler from a programmatic point of vuiew to do this. The logic before the instatiate sets of the position of the respective pieces on the board. If we did this from awake the cadence wouldn't be the same...

**Correction:**
- The precise reason: **the piece doesn't know its grid coordinates from inside `Awake()`.**
- `Awake` is for *self-knowledge* — what a script can figure out by looking at its own components/GameObject.
- Grid coords are *injected knowledge* — they live in the spawner's loop variables (`x`, `z`) and must be passed in.
- You *could* back-derive (`Mathf.RoundToInt(transform.position.x / tileSpacing)`), but that couples Piece to spawner-side assumptions about spacing/origin. Cleaner: spawner injects, piece holds.

## Phase VIII — Editor issues encountered & fixes

**`??=` flagged as "Unity objects should not use coalescing assignment".** Unity overrides `==` so destroyed-but-not-null references still compare equal to null. C# operators that bypass that override (`??`, `??=`, `is null`) silently disagree. Rule: **for `UnityEngine.Object` references, always `if (x == null)`.** Pure C# classes can use `??` freely.

**`Selection` class name collision.** `UnityEditor.Selection.objects` is a real Unity API. Naming a global-namespace class `Selection` shadows it and breaks any editor script that references `Selection.objects`. The URP template's `ReadmeEditor.cs` did exactly that. **Renamed to `PieceSelector`.** Avoid Unity's reserved-feeling names: `Object`, `Selection`, `Random`, `Camera`, `Light`, `Time`. Or wrap your code in a `namespace`.

**"Script class cannot be found" when adding component.** Means the project isn't compiling. Check the Console for any error — a single failed script blocks the whole assembly, which prevents Add Component from finding *any* of your new classes. Fix the error first.

## End of Phase VIII
24 pieces spawn programmatically; clicking a piece selects it (pulse animation) and clicking another swaps; clicking empty space deselects. Ready for Phase IX — diagonal move validation and execution: clicking a *tile* after selecting a piece moves the piece if the move is legal.

---

# Phase IX — Move Validation & Execution

## Concepts (primer)
- **Board state model** — `Piece[,]` 2D array as source of truth for "what's at (x, z)?". O(1) lookup; reflects committed logical state, not transient world positions.
- **Singleton** — `public static Board Instance { get; private set; }` set in `Awake()`. One global access point.
- **Coroutine** — yields control each frame. Used for time-based animations (slide).
- **Direction constraint** — non-king white moves +Z, non-king black moves -Z. Forward-only creates game progression.
- **Diagonal-by-1** — `Mathf.Abs(dx) == 1 && Mathf.Abs(dz) == 1`.

## Scripts created/updated

### Tile.cs (new)
Simple grid coords holder, attached to each tile.

### Board.cs (new singleton)
Owns the 2D `Piece[,]` grid. Provides `IsInBounds`, `GetPieceAt`, `IsEmpty`, `PlacePiece`, `ClearSquare`, `IsValidMove`. `IsValidMove` checks: in-bounds, target empty, dark square, diagonal-by-1, forward direction (or king).

### Piece.cs (extended)
Added `IsMoving` flag, `SetGridPosition(x, z)`, `StartMoveTo(target, duration)` and `MoveCoroutine` (Lerp position over time, fires `triggerMove` animator parameter at start, sets `IsMoving` true/false around the loop).

### BoardGenerator.cs (extended)
After instantiating each tile, `AddComponent<Tile>()` (defensive) and `Initialize(x, z)`.

### PieceSpawner.cs (extended)
After spawning each piece, `Board.Instance.PlacePiece(piece, x, z)` to register in the grid.

### PieceSelector.cs (rewritten)
- Two layer masks: `pieceLayer` and `tileLayer`.
- `Update()` early-returns if a piece is mid-move.
- `HandleClick`: try piece-raycast first; if hit a piece, select/swap/toggle. Else, if a piece is selected and tile-raycast hits a tile, attempt move. Else deselect.
- `TryMoveTo`: validate via `Board.IsValidMove`; if legal, update grid (`ClearSquare` old, `PlacePiece` new), call `SetGridPosition`, `StartMoveTo`, deselect.

## Editor steps
- Add `Tile` component to `Tile.prefab` (optional — `BoardGenerator` AddComponents defensively).
- Create empty `Board` GameObject in Hierarchy. Reset Transform. Add Component → `Board`.
- On `GameManager` PieceSelector: split layer masks (Piece Layer = `Pieces`, Tile Layer = `Board`). Set Move Duration `0.4`, Piece Y `0.2` (matching spawner).

## Knowledge check

### Q1 — Array vs raycasting
**User's answer:** Lookup table is faster; raycasting is more onerous; layers complicate things.

**Correction / expansion:**
- **Performance:** array index is O(1); raycasting walks Unity's physics tree, much more expensive, and we'll check many candidate squares per turn in jump search.
- **Logical vs visual state:** during a slide coroutine, `transform.position` is *between* squares. The physics world reflects rendering, the grid array reflects committed logical state. Raycasting mid-slide gives nonsense answers.

### Q2 — Singleton failure mode
**User's answer:** Cart before the horse — board tiles may come after pieces. MonoBehaviour helps prevent this.

**Correction:**
- Concretely: `Board.Instance` is null until `Board.Awake()` runs. Calling `Board.Instance.X()` on null = NullReferenceException.
- Unity does NOT guarantee Awake order between scripts on different GameObjects.
- **Protection in this codebase:** all `Awake()` complete before any `Start()`. We only touch `Board.Instance` from `Start()`/`Update()`, never from another script's `Awake()`.
- **Where it bites:** accessing `Board.Instance` from another script's `Awake()` would race. Fixes: Script Execution Order setting, or null-guard with a one-frame retry.

### Q3 — Coroutine for slide
**User's answer:** Provides uniformity; extensible to future king/multi-jump.

**Correction:**
- Off-target. Real reasons:
  1. **Visual feedback** — instant snap is confusing; the player can't track the move. 0.4s slide makes "before → after" visible.
  2. **Frame-by-frame interpolation, cleanly** — coroutine local variables persist across yields, replacing what would be a manual state machine in `Update()` (started? when? where from? elapsed?).
  3. **Non-blocking** — yields back to Unity so input/render keep running. A `while` loop in a method would freeze the game.

### Q4 — Direction constraint
**User's answer:** Absolute value would let pieces move in both directions before being kinged, which is wrong.

**Verdict:** Correct. Concrete game-design failure: pieces could shuffle back and forth indefinitely with no pressure to engage — no progression, no forced confrontation. Forward-only is what creates inevitability of contact.

## End of Phase IX
Board state model + diagonal move validation + coroutine-based slide. Pieces obey direction and only move to legal empty dark squares. Ready for Phase X — captures, multi-jump chains, king promotion.

---

# Phase X — Captures, Jumps & King Promotion

## Concepts (primer)
- **Two move types** — *step* (`|dx|=|dz|=1`) and *jump* (`|dx|=|dz|=2` with enemy on midpoint).
- **`out` parameter** — atomic dual return: same-call evaluation of "valid?" + "captured what?".
- **Chain jump** — after a successful jump, if the piece can immediately jump again, stay selected.
- **Promotion** — reaching the opposite back rank crowns the piece (king moves and jumps in all 4 diagonals).
- **Visual king cue** — assign `Mat_Piece_King` via `meshRenderer.sharedMaterial = kingMaterial` (safe ref swap, doesn't mutate asset properties).

## Scripts updated

### Board.cs
- `IsValidMove(piece, x, z, out Piece captured)` — handles both step and jump in one entry point. Step → `captured = null`. Valid jump → `captured = midPiece`.
- Forward-direction check generalized to `(dz > 0 ? 1 : -1) != forwardSign` (works for both `|dz|=1` and `|dz|=2`).
- `HasJumpAvailable(piece)` — iterates 2 (or 4 for kings) jump directions; returns true if any is valid.

### Piece.cs
- New fields: `meshRenderer`, `kingMaterial`, `captureFadeDuration`.
- `Promote()` — sets `IsKing`, `isPromoted` animator bool, swaps to king material.
- `HandleCapture()` — fires `triggerCapture` then `Destroy(gameObject)` after a delay.
- `TriggerCaptureHash` parameter cached.

### PieceSelector.cs
- `IsValidMove` called with `out Piece captured`.
- After updating board state and grid position, checks for promotion (`GridZ == backRank`).
- Chain-jump branch: `if (captured != null && HasJumpAvailable(moved)) return;` — keeps selection for chaining.
- `TryGetComponent` swapped in to silence the GetComponent allocation hint.

## Editor steps
- On both piece prefabs: `Piece` component → drag `Mat_Piece_King` into King Material; Capture Fade Duration `0.3`.

## Knowledge check

### Q1 — `out` parameter
**User's answer:** Self-contained logic, modular, check correctness of one function not two.

**Correction:**
- The deeper *correctness* benefit is **atomicity**. Two separate calls (`IsValidMove` + `GetCaptured`) can race against state changes — the second sees a different world than the first did. `out` packs both outputs into one indivisible call: caller can't use one without the other, and both reflect the *same evaluation*. No state-drift opportunity.

### Q2 — `captured != null` guard
**User's answer:** NPE risk if removed.

**Correction:**
- Wrong reason. `HasJumpAvailable` is safe to call always — it returns false when no jumps exist. No NPE.
- Real issue: **rules.** Without the guard, after a step move the piece could chain-jump if a jump is available from its new square. Checkers rules disallow combining a step + jump in one turn. The guard enforces the rule. Bonus: avoids a wasted traversal on every step.

### Q3 — Destroy vs SetActive(false)
**User's answer:** Destroy frees memory; SetActive leaves the piece on board but immobile.

**Verdict:** Right intuition. Detail: Destroy = end-of-frame removal + GC; SetActive(false) = instant toggle, no GC, lives in memory and re-enable-able. SetActive is the basis of **object pooling** (frequently respawned objects). For checkers captures, Destroy is appropriate — pieces don't return in a single game. SetActive would matter for undo/replay or roguelike resurrect mechanics.

### Q4 — Promotion timing
**User's answer:** Could result in using king abilities without becoming one.

**Correction / expansion:**
- Order matters specifically for the **back-rank-jump-then-chain-backward** corner case.
- Current order (promote before chain check): if a piece reaches back rank via jump and could chain-jump backward (kings can), it's allowed in the same turn — *more permissive* than tournament rules.
- Reversed order (chain check first, promote after): the chain check sees the piece as non-king; only forward jumps qualify; piece is already at back rank → chain ends. Then promote. *Strict tournament rules.*
- Our code is the lenient version by choice. Worth knowing it's a real design knob.

## Phase X — IDE diagnostic & fix

`GetComponent` warning. `TryGetComponent(out T)` is the non-allocating alternative — returns bool, writes to out param. Used in PieceSelector for both raycast hit checks. No behavior change; cleaner perf.

## End of Phase X
Captures remove the jumped enemy; chain jumps stay selected for follow-up; back-rank promotion swaps to gold king material and unlocks backward movement. Ready for Phase XI — turn system + greedy AI for the Black side, so a full game can be played start to finish.

---

# Concept Deep-Dive: The `out` parameter

Introduced in Phase X via `IsValidMove(piece, x, z, out Piece captured)`. Worth a deeper look because the pattern shows up everywhere in Unity (`Physics.Raycast`, `TryGetComponent`, `Dictionary.TryGetValue`).

## What it is

`out` is a C# **parameter modifier** that flips a parameter from "input to the method" into "output from the method." Three rules govern it:

1. The caller **doesn't have to initialize** the variable before passing it in. It can be declared inline at the callsite.
2. The method **must assign it** on every code path before returning. The compiler enforces this — if any branch leaves it unassigned, you get a compile error.
3. The method **cannot read it** before assigning it. It's write-only inside the method body.

Comparison with cousins:
- **regular parameter** — input only, value copied in.
- **`ref` parameter** — input *and* output. Caller must initialize. Method reads the existing value, can write back.
- **`out` parameter** — output only. Caller can leave uninitialized. Method must write.
- **`in` parameter** — input only, but passed by reference (no copy). Method cannot modify.

## Why the language has it

Single-return-value functions are limiting when a method genuinely has *two* answers that belong together. Three options exist:

```csharp
// Option A: split into two methods (DANGER)
bool IsValidMove(Piece p, int x, int z) { ... }
Piece GetCapturedFor(Piece p, int x, int z) { ... }
// Caller:
if (IsValidMove(p, x, z)) {
    var captured = GetCapturedFor(p, x, z);  // re-evaluates from scratch
}

// Option B: tuple return
(bool valid, Piece captured) IsValidMove(Piece p, int x, int z) { ... }
// Caller:
var (valid, captured) = IsValidMove(p, x, z);
if (valid) { ... }

// Option C: out parameter
bool IsValidMove(Piece p, int x, int z, out Piece captured) { ... }
// Caller:
if (IsValidMove(p, x, z, out Piece captured)) { ... }
```

**Option A is the trap.** The two calls happen at *different points in time*. If anything mutates the world between them — another script's Update fires, a coroutine yields, the user clicks — the second call sees a different board than the first. They can disagree. That's a real bug class.

**Options B and C are both atomic.** Both run the validation logic exactly once and return both pieces of information together. They differ in style: tuples are newer C#, slightly more verbose at the callsite, and don't compose as naturally with Unity's existing API. `out` is what Unity itself uses, so it reads as idiomatic.

## How `out` structures logic

Look at our `IsValidMove`:

```csharp
public bool IsValidMove(Piece piece, int targetX, int targetZ, out Piece captured)
{
    captured = null;                    // assign on every path
    if (!IsInBounds(...)) return false; // captured stays null
    ...
    if (isStep) return true;            // captured stays null
    ...
    captured = middle;                  // assign for jump path
    return true;
}
```

The compiler **forces** us to handle `captured = null` for every early-return branch. We can't accidentally return `true` and forget to set `captured` — the code wouldn't compile.

Inside the method, `captured = X` is the *only* way to communicate the second answer to the caller. There's no temptation to stash it in a field, no risk of stale state. The two outputs are bound to a single call.

At the callsite, the variable is declared **inline**:
```csharp
if (Board.Instance.IsValidMove(piece, x, z, out Piece captured))
{
    // captured is in scope and definitely assigned
    if (captured != null) { ... }
}
```

The variable's scope is exactly where it's meaningful. No declare-before-call boilerplate, no chance of typo'ing a separate variable name.

## When you reach for it

- You need a method to return two related pieces of data.
- Returning a tuple feels heavy or unidiomatic in the codebase.
- The "did this succeed?" + "here's the result" pattern (the entire `Try*` family in .NET).
- You want compile-time enforcement that the second output is always set.

When *not* to use it: deeper output (3+ values), or when the outputs aren't tightly coupled to a single bool. At that point, return a small struct/class instead.

---

# Phase XI — Turn System & Greedy AI

## Concepts (primer)
- **Singleton + event** — `TurnManager.Instance` + `event Action<PieceColor> OnTurnChanged`. Anyone can subscribe; only owner can fire.
- **`Move` struct** — value-type record (piece, target, captured) passed around to AI and executor.
- **`MoveExecutor`** — extracted shared move-execution path used by both human and AI.
- **Greedy AI** — generate all legal moves, score each (capture +3, promotion +2, advance +1), pick highest, random tie-break.
- **Stalemate detection** — `EndTurn` queries `Board.GetAllMoves(newSide)`; if zero, the side just stalemated, opposite side wins.

## Scripts created/updated

### Move.cs (new)
```csharp
public struct Move { public Piece piece; public int targetX, targetZ; public Piece captured; }
```

### TurnManager.cs (new)
- Singleton with `CurrentTurn`, `GameOver`, events `OnTurnChanged` and `OnGameOver`.
- `EndTurn` toggles, then checks if the new side has any legal moves. Zero → game over with opposite-side winner.
- `Start()` fires initial `OnTurnChanged` so subscribers initialize.

### MoveExecutor.cs (new)
- Singleton. `Execute(Move)` updates board state, captures the enemy if any, animates the slide, promotes if reaching back rank, returns `bool chainAvailable`.

### AI.cs (new)
- Subscribes to `OnTurnChanged` in Start; unsubscribes in OnDestroy.
- `TakeTurn` is a `do-while` loop that picks → executes → waits for slide → repeats while chains are available, then `EndTurn`.
- `ChooseMove` collects top-scoring moves, picks one at random for tie-breaking.
- `ScoreMove`: +3 capture, +2 promotion, +1 baseline.

### Board.cs (extended)
- `GetAllMoves(PieceColor)` — iterates the grid, tries 4 diagonals × 2 distances per piece, validates via `IsValidMove`.

### PieceSelector.cs (rewritten)
- Update gates: `GameOver`, `CurrentTurn != humanColor`, `IsMoving`.
- `HandlePieceClick` rejects opponent-color pieces.
- `TryMoveTo` builds a `Move`, calls `MoveExecutor.Instance.Execute`, calls `TurnManager.Instance.EndTurn` if no chain.
- `humanColor` field — flip to play as Black against a White AI.

## Editor steps
- Empty GameObjects: `TurnManager`, `MoveExecutor`, `AI` — each with their respective component.
- AI: AI Color = Black, Think Delay 0.6, Post Move Delay 0.2.
- PieceSelector: Human Color = White.
- `pieceY` must match across `PieceSpawner` and `MoveExecutor` (0.2).

## Knowledge check

### Q1 — Events vs polling
**User's answer:** Game is synchronous; polling isn't necessary; prevents race conditions.

**Correction / expansion:**
- Unity's main loop is single-threaded — race conditions aren't really the concern.
- Real benefits: **(1) work avoidance** (polling runs ~60×/sec; event runs once per change), **(2) no missed-transition bookkeeping** (polling needs `lastSeenTurn` tracking; events fire exactly once per change), **(3) decoupling** (TurnManager doesn't know who listens; subscribers attach themselves).

### Q2 — MoveExecutor extraction
**User's answer:** DRY principle; otherwise sloppy codebase.

**Verdict:** Correct. Concrete win = **single point of correctness**: future rules (sound on capture, turn timer, undo state, network sync) get one edit. Duplicated code drifts.

### Q3 — do-while in AI.TakeTurn
**User's answer:** Executes once then iterates; cleaner than alternatives.

**Verdict:** Correct. Specific reason: AI must execute exactly one move per turn minimum. `while` would check the condition before any move executes — `chainAvailable` only gets a value after the first move, requiring duplicate logic. `do-while` runs the body once unconditionally, then loops on the post-condition.

### Q4 — Greedy blind spot
**User's answer:** AI takes a less interesting capture instead of blocking; player can backtrack with king.

**Correction / expansion:**
- Right defensive flavor; the canonical example is the **sacrifice trap**: player offers a piece, AI takes (+3 score), but the landing square is jumpable by the player's next move (-3). Net: even trade.
- Greedy scores its own move in isolation; it doesn't simulate the opponent's response.
- 1-move-lookahead minimax would compute: "for each candidate, what's the best reply opponent can make? Subtract that from my score." The trap move scores 0 instead of +4 → AI picks a safer +1 advance.

## End of Phase XI
Turn alternation enforced. Input gated by current turn. AI plays Black greedily with chain-jump support and random tie-break. Stalemate detection wired (no-moves = opponent wins). Ready for Phase XII — particles & audio feedback for moves, captures, promotions, UI clicks.

---

# Phase XII — Particles & Audio Feedback

## Concepts (primer)
- **ParticleSystem modules** — Main, Emission, Shape, Color over Lifetime, Size over Lifetime, Renderer. Each toggleable.
- **`Stop Action: Destroy`** — declarative auto-cleanup when last particle dies. No coroutine needed.
- **`PlayOneShot(clip)`** — layers a clip over the AudioSource's current output. Multiple calls overlap. `Play()` interrupts whatever's currently playing.
- **`AudioClip.Create()` + `SetData(samples, 0)`** — synthesize PCM samples in code, no .wav imports.
- **Sample rate** — 44100 = CD quality; for blips, lower works fine.

## Scripts created/updated

### AudioManager.cs (new)
Singleton with one AudioSource. In Awake, generates four clips procedurally:
- `moveClip` — 440 Hz square tone, 80 ms, fade-out envelope.
- `captureClip` — sine sweep 660 → 220 Hz, 180 ms (descending = "loss").
- `promoteClip` — major arpeggio (A, C#, E, A), 90 ms per note.
- `uiClickClip` — white noise burst, 50 ms.
Exposes `PlayMove`, `PlayCapture`, `PlayPromote`, `PlayUIClick`.

### EffectsManager.cs (new)
Singleton holding `captureSparksPrefab`. `SpawnCaptureEffect(Vector3 worldPos)` instantiates the prefab at `(x, spawnY, z)`.

### MoveExecutor.cs (extended)
- Capture branch: caches `move.captured.transform.position`, calls `PlayCapture`, calls `SpawnCaptureEffect`.
- Step branch (`else`): calls `PlayMove`. (Capture doesn't also play move — capture is the more salient sound.)
- Promotion branch: calls `PlayPromote` after `Promote()`.

## Editor steps
- `CaptureSparks` ParticleSystem in scene: Duration 0.5, Looping off, Start Lifetime 0.5, Start Speed 4, Start Size 0.12, Start Color orange-yellow, Stop Action Destroy.
- Emission: Rate 0, single Burst (Time 0, Count 20).
- Shape: Sphere, Radius 0.05.
- Color over Lifetime: alpha gradient 1 → 0.
- Size over Lifetime: curve 1 → 0.
- Renderer: `Default-ParticleSystem` material, Billboard mode.
- Save as `Assets/Prefabs/CaptureSparks.prefab`. Delete scene instance.
- Empty GameObjects: `AudioManager` (Audio Manager component, AudioSource auto-attached), `EffectsManager` (drag prefab into slot, spawnY 0.3).
- ResetButton → On Click() → `+` → drag AudioManager → select `AudioManager.PlayUIClick`.

## Knowledge check

### Q1 — PlayOneShot vs Play
**User's answer:** PlayOneShot uniformly scales volume; Play might result in different volume levels.

**Correction:**
- Volume isn't the issue. `Play()` plays the AudioSource's *current* clip and **restarts** if already playing — interrupts in-progress sound. `PlayOneShot(clip)` **layers** the new clip over whatever is playing; multiple calls overlap.
- Concrete bug with Play: mid-move sound, a capture fires; `Play(captureClip)` truncates the move sound or requires swapping `source.clip = captureClip` first. PlayOneShot lets both sounds play cleanly together.

### Q2 — Procedural audio
**User's answer:** Tighter coupling; fine-grained control; lose ability to develop richer sounds.

**Correction / expansion:**
- Phrasing: it's "tighter integration with code," not coupling.
- Gained: zero file size in build; parametric (could pass freq per call); fully self-contained build.
- Lost: limited to simple waveforms (sine/square/sweep/noise); slow iteration (recompile to hear changes); no DAW workflow for audio designers.

### Q3 — Stop Action: Destroy
**User's answer:** Wasting resources before GC reclaims them.

**Correction:**
- Unity's `Destroy` is explicit, not GC-based.
- Without Stop Action: Destroy, the spawned GameObject + dormant ParticleSystem live forever. Particles fade visually but the GO stays in the Hierarchy.
- Over a long game with many captures = dozens of dead invisible GameObjects accumulating.
- Stop Action: Destroy is the **declarative auto-cleanup**. The alternative (`Destroy(go, 1.5f)` or a coroutine) works but requires extra code and edge-case handling.

### Q4 — Singleton vs broadcast events
**User's answer:** Singletons self-contained; events not necessary for small project.

**Correction / expansion:**
- Right call for our scope. The trade-off matrix:
  - **Singleton call** — simple, traceable; but caller is *coupled* to the listener. Adding a new feedback system means editing the caller.
  - **Broadcast event** — caller fires and forgets; new listeners subscribe independently with no caller edits. But flow is harder to trace ("who reacts to OnCapture?" needs a search).
- Rule of thumb: 1–2 listeners → direct calls. Many listeners (analytics, achievements, tutorial hints, replay) → events scale better.

## End of Phase XII
Procedural audio for move/capture/promote/UI; spark burst on capture. The game now has consistent sensory feedback. Ready for Phase XIII — UI polish: turn indicator binding, piece counts, game-over panel, working Reset button.

---

# Phase XIII — UI Polish

## Concepts (primer)
- **`SceneManager.LoadScene(name)`** — destroys/rebuilds the named scene from scratch. Simplest reset. Loses any state not marked `DontDestroyOnLoad`.
- **Subscribe/unsubscribe pairing** — `+= handler` in Start, `-= handler` in OnDestroy. Forgetting unsubscribe leaks listeners across scene reloads.
- **Multiple OnClick handlers** — Unity buttons store a list. Each entry runs top-to-bottom. We add a Reset entry alongside the existing PlayUIClick.

## Scripts created/updated

### GameUI.cs (new)
- Subscribes to `OnTurnChanged` and `OnGameOver` in `Start`; unsubscribes in `OnDestroy`.
- Hides `gameOverPanel` in Start, then immediately invokes `HandleTurnChanged(CurrentTurn)` so UI initializes regardless of script execution order.
- `UpdatePieceCounts` scans the 8×8 grid (cheap), updates White: N / Black: N text on every turn change.
- `HandleGameOver(winner)` shows the panel with text "{winner} wins!".
- `ResetGame()` is `public void` for the Reset button to invoke via OnClick: `SceneManager.LoadScene(SceneManager.GetActiveScene().name)`.

### Reset button OnClick
Two handlers:
1. `AudioManager.PlayUIClick` (from Phase XII)
2. `GameUI.ResetGame` (new)

### UI Hierarchy additions
- `WhiteCount` and `BlackCount` TMP text elements anchored top-left.
- `GameOverPanel` (semi-transparent overlay) containing `GameOverText` ("White wins!" placeholder).

## Knowledge check

### Q1 — Scene reload vs manual reset
**User's answer:** Easier to just reload; manual better when fewer states.

**Correction:**
- Backwards. Manual reset is harder when there are *many* states (more things to remember to reset).
- Real trade-off:
  - **Reload:** trivially correct (impossible to forget); but loses all state not marked `DontDestroyOnLoad`. Brief load hitch.
  - **Manual:** preserves chosen state across resets (high score, settings); faster; but every new system needs its own reset path or you ship a "starts dirty" bug.
- Reload is right for us. Becomes wrong the moment we add meta-progression (roguelike runs).

### Q2 — Subscribe in Start, not Awake
**User's answer:** Need GameObjects loaded first; Awake might subscribe before they exist.

**Correction:**
- All GameObjects are instantiated by Awake. The real issue is **singleton init order**.
- `TurnManager.Instance` is set in `TurnManager.Awake()`. Unity doesn't guarantee Awake order between GameObjects. If `GameUI.Awake()` runs first, `Instance` is null → NPE.
- The contract that protects us: **all `Awake()` finish before any `Start()` runs.** By Start, every singleton's Instance is guaranteed set.

### Q3 — Immediate HandleTurnChanged call
**User's answer:** Keeps track of proper state; UI might have trouble.

**Correction / expansion:**
- `TurnManager.Start()` fires `OnTurnChanged` once at startup. If `GameUI.Start()` subscribes after that fired, we miss it.
- Unity doesn't guarantee Start order either.
- Without the immediate call, UI would show its **editor-placeholder text** until the first actual turn change (i.e., after a player moves a piece). Counts would lie at "12/12" indefinitely.
- The immediate call hedges against missed events at scene start.

### Q4 — Defensive null checks
**User's answer:** Avoid NPEs; UI directly affects visuals; gameplay can rely on impossible states.

**Verdict:** Right idea. Concretely:
- UI scripts rely on many `[SerializeField]` references **manually dragged via the Inspector**. Easy to forget → null at runtime. Guards say "tolerate a missing wire" — broken text shows but the rest still updates.
- Gameplay scripts use code-set/auto-found references (`GetComponent`, `RequireComponent`, `Initialize()` injection). Fewer manual wiring points = fewer null paths.
- Defense-in-depth tied to **how easy the script is to misconfigure.** UI is easiest to break by editor mistake → guard everywhere.

## End of Phase XIII
Turn indicator + piece counts bind to game state via events; game-over panel announces the winner; Reset button reloads the scene. The game is feature-complete. Ready for Phase XIV — packaging the game as a standalone macOS app.
