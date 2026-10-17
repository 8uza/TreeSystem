--!optimize 2
--[[
	TreeDemo.server.lua  (ServerScriptService)

	Spreads a showcase forest so every species can be compared side by side.

	Delete this once you have your own spawn logic.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local TreeGenerator = require(ReplicatedStorage.TreeSystem.TreeGenerator)
local TreeTypes = require(ReplicatedStorage.TreeSystem.TreeTypes)

local GROUND_SIZE = 300
local GROUND_Y = 0
local SPACING = 26

local function buildGround()
	if workspace:FindFirstChild("TreeDemoGround") then
		return
	end

	local ground = Instance.new("Part")
	ground.Name = "TreeDemoGround"
	ground.Size = Vector3.new(GROUND_SIZE, 4, GROUND_SIZE)
	ground.Position = Vector3.new(0, GROUND_Y - 2, 0)
	ground.Anchored = true
	ground.Material = Enum.Material.Grass
	ground.Color = Color3.fromRGB(86, 132, 62)
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.CanCollide = true
	ground.Parent = workspace
end

local function buildShowcase()
	-- every species at full size, straight from TreeTypes so it stays in sync
	for i, name in ipairs(TreeTypes.names()) do
		TreeGenerator.spawn(Vector3.new((i - 1) * SPACING, GROUND_Y, -14), name, 400 + i)
	end

	-- three seeds of one species, to show the shape varies
	for i = 1, 3 do
		TreeGenerator.spawn(Vector3.new((i - 1) * 26, GROUND_Y, 26), "Oak", 900 + i)
	end

	-- and a random crowd in the distance
	TreeGenerator.spawnForest(Vector3.new(80, GROUND_Y, 70), 45, 20)
end

buildGround()
buildShowcase()

Lighting.ClockTime = 14.5
Lighting.Brightness = 2.2
Lighting.OutdoorAmbient = Color3.fromRGB(120, 130, 150)

_G.TreeDemo = {
	treeGenerator = TreeGenerator,
	treeTypes = TreeTypes,
	clear = TreeGenerator.clear,
	spawn = TreeGenerator.spawn,
}

print("[TreeDemo] showcase ready")
