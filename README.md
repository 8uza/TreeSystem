# TreeSystem

Procedural trees for Roblox, in the Lumber Tycoon 2 style.

```lua
local TreeGenerator = require(ReplicatedStorage.TreeSystem.TreeGenerator)

TreeGenerator.spawn(Vector3.new(0, 0, 0))             -- random species
TreeGenerator.spawn(Vector3.new(0, 0, 0), "Pine")     -- named species
TreeGenerator.spawn(Vector3.new(0, 0, 0), "Oak", 7)   -- fixed seed
TreeGenerator.spawnForest(Vector3.new(0, 0, 0), 40, 80)
```

Five species ship with it: Oak, Pine, Birch, Maple, Palm. Every tree comes back
as a `Model` under `workspace.Trees`.

## Install

| From | To | Type |
| --- | --- | --- |
| `src/ReplicatedStorage/TreeSystem/TreeGenerator.lua` | `ReplicatedStorage > TreeSystem` | ModuleScript |
| `src/ReplicatedStorage/TreeSystem/TreeTypes.lua` | `ReplicatedStorage > TreeSystem` | ModuleScript |
| `src/ServerScriptService/TreeDemo.server.lua` | `ServerScriptService` | Script, optional |

The two modules have to sit next to each other, since `TreeGenerator` requires
`TreeTypes` through `script.Parent`.

`TreeDemo` is not a dependency. It lays one of each species in a row, puts three
seeds of the same species beside each other, scatters a forest behind them, and
overrides Lighting. Press Play with it in place and you get a showcase you can
walk around in. Delete it once you have your own spawn logic.

To do the same thing yourself:

```lua
local TreeGenerator = require(ReplicatedStorage.TreeSystem.TreeGenerator)
local TreeTypes = require(ReplicatedStorage.TreeSystem.TreeTypes)

for i, name in ipairs(TreeTypes.names()) do
	TreeGenerator.spawn(Vector3.new((i - 1) * 26, 0, 0), name)
end
```

## The look

Exactly two levels of branching, no more:

```
trunk - one straight box
limb  - 1 to 3 long branches off the top of the trunk
twig  - 1 to 4 short branches at the end of each limb
leaf  - one chunky box on the tip of each twig
```

The rigidity is the point. Every piece is a single straight box, which is what
makes these read as geometric instead of organic. Adding a third level, or
letting the trunk bend, turns them into generic procedural trees.

## API

| | |
| --- | --- |
| `spawn(position, species, seed, growth)` | One tree. `position` takes a `Vector3` or `CFrame`. `species` is a name, a config table, or nil for random. `seed` fixes the shape. `growth` is 0 to 1. Returns the Model. |
| `spawnForest(center, radius, count, species)` | Scatters trees in a circle. Uses a `sqrt` distribution so they spread evenly instead of bunching in the middle. Returns an array of Models. |
| `remove(model)` | Destroys one tree. |
| `clear()` | Destroys everything in `workspace.Trees`. |
| `generateLayout(config, seed)` | The virtual tree. Returns a table of segment and leaf records, creates no instances. Useful if you want the geometry without the parts. |
| `build(model, layout, growth)` | Turns a layout into parts on an existing Model. |
| `getFolder()` | The `workspace.Trees` folder, created on demand. |

Passing a `CFrame` to `spawn` or `spawnForest` orients the tree, since `PivotTo`
is what places it.

### Partial growth

`growth` is not a scale factor on the whole model, it's a height threshold.
`build` walks the layout and only creates the boxes below that height, so a
younger tree genuinely costs fewer parts instead of being a scaled-down copy.
Pass `0.4` and you get a short trunk and nothing above it.

Re-run `build` on the same model to change its size, and reuse the same layout
to change how grown it looks without generating the shape again:

```lua
local layout = TreeGenerator.generateLayout(TreeTypes.presets.Oak, 7)
local model = TreeGenerator.spawn(Vector3.zero, "Oak", 7)

TreeGenerator.build(model, layout, 0.3)  -- sapling
TreeGenerator.build(model, layout, 1)    -- full size, same shape
```

## Making your own

A species is a plain table. Everything except `name` falls back to the Oak
preset, so you only override what you care about:

```lua
local myTree = {
	name = "Dead",
	trunkHeight = 9,
	trunkColor = Color3.fromRGB(84, 72, 60),
	limbCount = { min = 1, max = 2 },
}

TreeGenerator.spawn(Vector3.new(0, 0, 0), myTree)
```

Numbers that describe a range are tables, `{ min = 2, max = 3 }`. The full set
of fields is on `TreeTypes.TreeConfig`, and each preset in `TreeTypes.presets`
is a working example of every one.

Every species has leaves, by design. To get a bare trunk, set `leafColors` to
an empty table and `leafSize` small enough to disappear rather than trying to
switch leaves off.

To add a species permanently, add a table to `TreeTypes.presets` with a
`name` field. `get`, `names` and `pickRandom` pick it up automatically.

## Notes

- The pivot part is created before anything else and parented first. Assigning
  `Model.PrimaryPart` re-pivots the model onto that part, so doing it after the
  trunk is built would silently shift every box down into the ground.
- Segment and leaf counts land on the Model as `SegmentCount` and `LeafCount`
  attributes, and growth goes on as `Size`.
- Parts are `Anchored` and `Massless`, which is fine for scenery. Don't parent a
  moving tree model under one without expecting physics complaints.
- `--!optimize 2` is set on all three files, so the closure-heavy path building
  is compiled ahead of time.
- Trees are plain Parts, not a mesh or an asset, so nothing streams in. A large
  forest costs part count, not memory bandwidth.

## License

MIT, see [LICENSE](LICENSE).
