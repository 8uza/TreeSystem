--!optimize 2
--[[
	TreeGenerator.lua

	Procedural Lumber Tycoon 2 style trees: one straight trunk, long limbs forking
	off the top, short twigs on those, and a chunky leaf box on every twig tip.

	Quick start
	-----------
	local TreeGenerator = require(game:GetService("ReplicatedStorage").TreeSystem.TreeGenerator)

	TreeGenerator.spawn(Vector3.new(0, 0, 0))            -- random species, random shape
	TreeGenerator.spawn(Vector3.new(0, 0, 0), "Pine")    -- a specific species
	TreeGenerator.spawn(Vector3.new(0, 0, 0), "Oak", 7)  -- fixed seed = same tree every time

	TreeGenerator.spawn(Vector3.new(0, 0, 0), "Oak", nil, 0.4)  -- a younger, smaller tree
	TreeGenerator.spawnForest(Vector3.new(0, 0, 0), 40, 80)

	Species are Oak, Pine, Birch, Maple and Palm.

	Every spawned tree is a Model parented to workspace.Trees.

	The shape
	---------
	Exactly two levels, no more:

	    trunk  - one straight box
	    limb   - 1 to 3 long branches off the top of the trunk
	    twig   - 1 to 4 short branches at the end of each limb
	    leaf   - one chunky box on the tip of each twig

	Nothing bends, leans or twists - every piece is a single straight box. That
	rigidity is the whole look; adding a third level of branching is what turns
	these into generic procedural trees instead of geometric ones.

	Partial growth
	--------------
	`build` takes a `growth` value (0..1) and instantiates only the boxes below it,
	so a smaller or younger tree costs nothing extra - just pass a number under 1.
]]

local TreeTypes = require(script.Parent.TreeTypes)

local rad = math.rad
local clamp = math.clamp
local max = math.max

local TreeGenerator = {}

local FOLDER_NAME = "Trees"

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

--- Merges a config over the Oak preset so callers can pass a partial table.
local function applyDefaults(config)
	local preset = TreeTypes.presets.Oak
	local d = {}

	for key, value in preset do
		local override = config[key]
		if override == nil then
			if type(value) == "table" then
				d[key] = table.clone(value)
			else
				d[key] = value
			end
		else
			d[key] = override
		end
	end
	for key, value in config do
		d[key] = value
	end

	d.name = config.name or "Tree"
	d.trunkHeight = max(1, d.trunkHeight)
	d.trunkWidth = clamp(d.trunkWidth, 0.2, 20)
	d.trunkTaper = clamp(d.trunkTaper, 0.2, 1)

	d.limbCount = d.limbCount or preset.limbCount
	d.limbLength = d.limbLength or preset.limbLength
	d.limbAngle = d.limbAngle or preset.limbAngle
	d.limbWidthRatio = clamp(d.limbWidthRatio, 0.2, 1)

	d.twigCount = d.twigCount or preset.twigCount
	d.twigLength = d.twigLength or preset.twigLength
	d.twigAngle = d.twigAngle or preset.twigAngle
	d.twigWidthRatio = clamp(d.twigWidthRatio, 0.2, 1)
	d.leafSize = max(0.4, d.leafSize)

	if #d.leafColors == 0 then
		d.leafColors = preset.leafColors
	end
	return d
end

local function jitter(rng, color, variance)
	if variance <= 0 then
		return color
	end
	local h, s, v = color:ToHSV()
	v = clamp(v + rng:NextNumber(-variance, variance), 0.05, 1)
	return Color3.fromHSV(h, s, v)
end

--------------------------------------------------------------------------------
-- Recording boxes
--------------------------------------------------------------------------------

local function pushSegment(layout, rng, config, frame, length, widthBottom, widthTop, isTrunk)
	layout.segments[#layout.segments + 1] = {
		frame = frame,
		length = length,
		widthBottom = widthBottom,
		widthTop = widthTop,
		isTrunk = isTrunk,
		color = jitter(rng, config.trunkColor, config.trunkColorVariance),
	}
end

--- One chunky leaf box, tilted so it sits on its twig rather than square to it.
local function pushLeaf(layout, rng, config, frame)
	local size = config.leafSize * rng:NextNumber(0.85, 1.15)
	layout.leaves[#layout.leaves + 1] = {
		cframe = frame
			* CFrame.Angles(
				rad(rng:NextNumber(-28, 28)),
				rad(rng:NextNumber(0, 360)),
				rad(rng:NextNumber(-28, 28))
			),
		size = Vector3.new(
			size * rng:NextNumber(1.15, 1.5),
			size * rng:NextNumber(0.42, 0.6),
			size * rng:NextNumber(1.0, 1.3)
		),
		color = config.leafColors[rng:NextInteger(1, #config.leafColors)],
	}
end

--------------------------------------------------------------------------------
-- Growth
--------------------------------------------------------------------------------

--- A short branch off the end of a limb, capped with one leaf.
local function growTwig(layout, rng, config, startFrame, length, width)
	pushSegment(layout, rng, config, startFrame, length, width, width * config.twigWidthRatio, false)

	pushLeaf(layout, rng, config, startFrame * CFrame.new(0, length, 0))
end

--- A long branch off the top of the trunk, with 1 to 4 twigs at the end of it.
local function growLimb(layout, rng, config, startFrame, length, width)
	pushSegment(layout, rng, config, startFrame, length, width, width * config.limbWidthRatio, false)

	local tip = startFrame * CFrame.new(0, length, 0)
	local count = rng:NextInteger(config.twigCount.min, config.twigCount.max)
	local spread = 360 / count
	local firstYaw = rng:NextNumber(0, 360)

	for i = 0, count - 1 do
		local yaw = rad(firstYaw + i * spread + rng:NextNumber(-config.twigAngleJitter, config.twigAngleJitter))
		local angle = rad(rng:NextNumber(config.twigAngle.min, config.twigAngle.max))

		growTwig(
			layout, rng, config,
			tip * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, angle),
			rng:NextNumber(config.twigLength.min, config.twigLength.max),
			width * config.twigWidthRatio
		)
	end
end

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

--- Walks a virtual tree and records every box. Creates no instances.
function TreeGenerator.generateLayout(config, seed)
	config = applyDefaults(config or TreeTypes.presets.Oak)
	local rng = Random.new(seed or math.random(1, 2 ^ 31 - 1))

	local layout = {
		config = config,
		seed = rng:NextInteger(1, 2 ^ 31 - 1),
		segments = {},
		leaves = {},
		totalHeight = config.trunkHeight,
	}

	-- ONE straight trunk. No lean, no bend, no twist.
	pushSegment(
		layout, rng, config,
		CFrame.new(0, 0, 0),
		config.trunkHeight,
		config.trunkWidth,
		config.trunkWidth * config.trunkTaper,
		true
	)

	-- Every limb grows off the top of the trunk.
	local limbCount = rng:NextInteger(config.limbCount.min, config.limbCount.max)
	local spread = 360 / limbCount
	local firstYaw = rng:NextNumber(0, 360)

	for i = 0, limbCount - 1 do
		local yaw = rad(firstYaw + i * spread + rng:NextNumber(-config.limbAngleJitter, config.limbAngleJitter))
		local angle = rad(rng:NextNumber(config.limbAngle.min, config.limbAngle.max))

		growLimb(
			layout, rng, config,
			CFrame.new(0, config.trunkHeight, 0) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(0, 0, angle),
			rng:NextNumber(config.limbLength.min, config.limbLength.max),
			config.trunkWidth * config.trunkTaper * config.limbWidthRatio
		)
	end

	-- Record how high each box sits, so build() can reveal the tree bottom-up.
	local maxY = config.trunkHeight
	for _, seg in ipairs(layout.segments) do
		maxY = max(maxY, seg.frame.Position.Y + seg.length)
	end
	for _, leaf in ipairs(layout.leaves) do
		maxY = max(maxY, leaf.cframe.Position.Y)
	end
	layout.totalHeight = maxY

	local divisor = max(maxY, 0.001)
	for _, seg in ipairs(layout.segments) do
		seg.heightFrac = clamp((seg.frame.Position.Y + seg.length) / divisor, 0, 1)
	end
	for _, leaf in ipairs(layout.leaves) do
		leaf.heightFrac = clamp(leaf.cframe.Position.Y / divisor, 0, 1)
	end

	return layout
end

--------------------------------------------------------------------------------
-- Building Parts
--------------------------------------------------------------------------------

local function makeSegmentPart(seg, material, collide)
	local part = Instance.new("Part")
	part.Name = "Segment"
	part.Size = Vector3.new(seg.widthBottom, seg.length, seg.widthBottom)
	part.CFrame = seg.frame * CFrame.new(0, seg.length * 0.5, 0)
	part.Anchored = true
	part.Material = material
	part.Color = seg.color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = true
	part.CanCollide = collide
	part.CanTouch = false
	part.CanQuery = collide
	part.Massless = true
	return part
end

local function makeLeafPart(leaf, material)
	local part = Instance.new("Part")
	part.Name = "Leaf"
	part.Size = leaf.size
	part.CFrame = leaf.cframe
	part.Anchored = true
	part.Material = material
	part.Color = leaf.color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	return part
end

local function getOrCreateFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function TreeGenerator.getFolder()
	return getOrCreateFolder(workspace, FOLDER_NAME)
end

--- Rebuilds a tree's boxes up to `growth` (0..1).
function TreeGenerator.build(model, layout, growth)
	local config = layout.config
	growth = clamp(growth, 0, 1)

	-- Create the pivot part BEFORE anything else. Assigning Model.PrimaryPart
	-- re-pivots the model onto that part, so doing it after the trunk is already
	-- built silently translates every box by the pivot's offset - which puts half
	-- the tree below the ground.
	if not model.PrimaryPart then
		local trunk = layout.segments[1]
		local pivot = Instance.new("Part")
		pivot.Name = "Pivot"
		pivot.Size = Vector3.new(trunk.widthBottom, trunk.length, trunk.widthBottom)
		pivot.CFrame = trunk.frame
		pivot.Anchored = true
		pivot.Material = config.trunkMaterial
		pivot.Transparency = 1
		pivot.CastShadow = false
		pivot.CanCollide = false
		pivot.CanTouch = false
		pivot.CanQuery = false
		pivot.Massless = true
		pivot.Parent = model
		model.PrimaryPart = pivot
	end

	local trunkFolder = getOrCreateFolder(model, "Trunk")
	local branchFolder = getOrCreateFolder(model, "Branches")
	local leafFolder = getOrCreateFolder(model, "Leaves")

	trunkFolder:ClearAllChildren()
	branchFolder:ClearAllChildren()
	leafFolder:ClearAllChildren()

	if growth > 0 then
		local seg = layout.segments[1]
		local shown = seg.length * clamp(growth / seg.heightFrac, 0.2, 1)
		local stub = makeSegmentPart(seg, config.trunkMaterial, config.collide)
		stub.Size = Vector3.new(seg.widthBottom, shown, seg.widthBottom)
		stub.CFrame = seg.frame * CFrame.new(0, shown * 0.5, 0)
		stub.Parent = trunkFolder
	end

	for _, seg in ipairs(layout.segments) do
		if not seg.isTrunk and seg.heightFrac <= growth then
			makeSegmentPart(seg, config.trunkMaterial, false).Parent = branchFolder
		end
	end

	for _, leaf in ipairs(layout.leaves) do
		if leaf.heightFrac <= growth then
			makeLeafPart(leaf, config.leafMaterial).Parent = leafFolder
		end
	end

	model:SetAttribute("Size", growth)
	model:SetAttribute("SegmentCount", #trunkFolder:GetChildren() + #branchFolder:GetChildren())
	model:SetAttribute("LeafCount", #leafFolder:GetChildren())
end

--------------------------------------------------------------------------------
-- Spawning
--------------------------------------------------------------------------------

local function toCFrame(positionOrCFrame)
	if positionOrCFrame == nil then
		return CFrame.new(0, 0, 0)
	end
	if typeof(positionOrCFrame) == "CFrame" then
		return positionOrCFrame
	end
	return CFrame.new(positionOrCFrame)
end

--- position : Vector3 | CFrame
--- species  : preset name, or a full config table (default: a random preset)
--- seed     : fix it to always get the same tree back
--- growth   : 0..1, defaults to 1. Below 1 gives a smaller, younger tree.
function TreeGenerator.spawn(position, species, seed, growth)
	local config
	if type(species) == "string" then
		config = TreeTypes.get(species)
		if not config then
			warn("[TreeGenerator] unknown species:", species)
			config = TreeTypes.presets.Oak
		end
	elseif type(species) == "table" then
		config = species
	else
		config = TreeTypes.pickRandom()
	end

	local layout = TreeGenerator.generateLayout(config, seed)

	local model = Instance.new("Model")
	model.Name = config.name
	model:SetAttribute("TreeSpecies", config.name)
	model:SetAttribute("TreeSeed", layout.seed)

	TreeGenerator.build(model, layout, growth or 1)
	model:PivotTo(toCFrame(position))
	model.Parent = TreeGenerator.getFolder()

	return model
end

function TreeGenerator.spawnForest(center, radius, count, species)
	local origin = toCFrame(center).Position
	local models = {}

	for _ = 1, (count or 20) do
		local angle = math.random() * math.pi * 2
		local distance = math.sqrt(math.random()) * (radius or 60)
		local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		models[#models + 1] = TreeGenerator.spawn(origin + offset, species)
	end

	return models
end

function TreeGenerator.remove(model)
	if model and model.Parent then
		model:Destroy()
	end
end

function TreeGenerator.clear()
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if folder then
		folder:ClearAllChildren()
	end
end

return TreeGenerator
