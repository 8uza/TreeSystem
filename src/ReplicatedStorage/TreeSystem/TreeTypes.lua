--!optimize 2
--[[
	TreeTypes.lua
	Species presets, in the Lumber Tycoon 2 style.

	An LT2 tree is deliberately rigid and geometric, and it is only ever two
	levels deep:

	    trunk  - one straight box, nothing more
	    limb   - 1 to 3 long branches, all growing off the top of the trunk
	    twig   - 1 to 4 short branches at the end of each limb
	    leaf   - one chunky box on the tip of each twig

	Nothing bends, leans or twists. Every piece is a single straight box, which is
	what makes it read as geometric rather than organic.

	Every species here has leaves: a tree with a bare trunk and nothing on it is
	not a tree.
]]

local TreeTypes = {}

export type TreeConfig = {
	name: string,

	-- Trunk: exactly one straight box ------------------------------------------
	trunkHeight: number,
	trunkWidth: number,
	trunkTaper: number,

	-- Limbs: the long branches off the top of the trunk -------------------------
	limbCount: { min: number, max: number },
	limbLength: { min: number, max: number },
	limbAngle: { min: number, max: number },
	limbAngleJitter: number,
	limbWidthRatio: number,

	-- Twigs: the short branches at the end of each limb ------------------------
	twigCount: { min: number, max: number },
	twigLength: { min: number, max: number },
	twigAngle: { min: number, max: number },
	twigAngleJitter: number,
	twigWidthRatio: number,

	-- Leaves: one chunky box per twig tip ---------------------------------------
	leafSize: number,
	leafColors: { Color3 },

	-- Look ---------------------------------------------------------------------
	trunkColor: Color3,
	trunkColorVariance: number,
	trunkMaterial: Enum.Material,
	leafMaterial: Enum.Material,
	collide: boolean,
}

local function cm(r, g, b)
	return Color3.fromRGB(r, g, b)
end

TreeTypes.presets = {
	Oak = {
		name = "Oak",
		trunkHeight = 12,
		trunkWidth = 1.5,
		trunkTaper = 0.85,

		limbCount = { min = 2, max = 3 },
		limbLength = { min = 8, max = 10 },
		limbAngle = { min = 38, max = 58 },
		limbAngleJitter = 12,
		limbWidthRatio = 0.8,

		twigCount = { min = 1, max = 3 },
		twigLength = { min = 3.5, max = 5.5 },
		twigAngle = { min = 20, max = 45 },
		twigAngleJitter = 14,
		twigWidthRatio = 0.7,

		leafSize = 6,
		leafColors = { cm(46, 96, 44), cm(56, 110, 48), cm(38, 82, 38) },

		trunkColor = cm(104, 72, 46),
		trunkColorVariance = 0.08,
		trunkMaterial = Enum.Material.Wood,
		leafMaterial = Enum.Material.Grass,
		collide = true,
	},

	Pine = {
		name = "Pine",
		trunkHeight = 18,
		trunkWidth = 1.4,
		trunkTaper = 0.9,

		limbCount = { min = 3, max = 4 },
		limbLength = { min = 6, max = 8 },
		limbAngle = { min = 45, max = 65 },
		limbAngleJitter = 10,
		limbWidthRatio = 0.78,

		twigCount = { min = 1, max = 2 },
		twigLength = { min = 3, max = 4.5 },
		twigAngle = { min = 18, max = 40 },
		twigAngleJitter = 12,
		twigWidthRatio = 0.68,

		leafSize = 4.5,
		leafColors = { cm(32, 78, 46), cm(40, 96, 54), cm(26, 66, 40) },

		trunkColor = cm(84, 60, 40),
		trunkColorVariance = 0.1,
		trunkMaterial = Enum.Material.Wood,
		leafMaterial = Enum.Material.Grass,
		collide = true,
	},

	Birch = {
		name = "Birch",
		trunkHeight = 15,
		trunkWidth = 1.3,
		trunkTaper = 0.85,

		limbCount = { min = 2, max = 3 },
		limbLength = { min = 8, max = 10 },
		limbAngle = { min = 32, max = 52 },
		limbAngleJitter = 14,
		limbWidthRatio = 0.76,

		twigCount = { min = 1, max = 3 },
		twigLength = { min = 3.5, max = 5 },
		twigAngle = { min = 18, max = 42 },
		twigAngleJitter = 16,
		twigWidthRatio = 0.68,

		leafSize = 5,
		leafColors = { cm(122, 172, 70), cm(144, 190, 84), cm(106, 152, 60) },

		trunkColor = cm(226, 222, 210),
		trunkColorVariance = 0.18,
		trunkMaterial = Enum.Material.Wood,
		leafMaterial = Enum.Material.Grass,
		collide = true,
	},

	Maple = {
		name = "Maple",
		trunkHeight = 11,
		trunkWidth = 1.8,
		trunkTaper = 0.8,

		limbCount = { min = 2, max = 3 },
		limbLength = { min = 7, max = 9 },
		limbAngle = { min = 36, max = 56 },
		limbAngleJitter = 10,
		limbWidthRatio = 0.8,

		twigCount = { min = 2, max = 4 },
		twigLength = { min = 3, max = 5 },
		twigAngle = { min = 20, max = 45 },
		twigAngleJitter = 14,
		twigWidthRatio = 0.68,

		leafSize = 6.5,
		leafColors = { cm(182, 68, 40), cm(206, 100, 46), cm(156, 52, 36) },

		trunkColor = cm(110, 80, 54),
		trunkColorVariance = 0.08,
		trunkMaterial = Enum.Material.Wood,
		leafMaterial = Enum.Material.Grass,
		collide = true,
	},

	Palm = {
		name = "Palm",
		trunkHeight = 20,
		trunkWidth = 1.6,
		trunkTaper = 0.95,

		-- a single ring of fronds, nothing below the crown
		limbCount = { min = 5, max = 6 },
		limbLength = { min = 7, max = 10 },
		limbAngle = { min = 55, max = 82 },
		limbAngleJitter = 14,
		limbWidthRatio = 0.6,

		twigCount = { min = 1, max = 1 },
		twigLength = { min = 2.5, max = 3.5 },
		twigAngle = { min = 12, max = 30 },
		twigAngleJitter = 12,
		twigWidthRatio = 0.6,

		leafSize = 6,
		leafColors = { cm(62, 140, 54), cm(82, 162, 64), cm(48, 116, 44) },

		trunkColor = cm(150, 126, 92),
		trunkColorVariance = 0.12,
		trunkMaterial = Enum.Material.Wood,
		leafMaterial = Enum.Material.Grass,
		collide = true,
	},
}

--- Returns a preset config by name (case-insensitive), or nil.
function TreeTypes.get(name)
	if type(name) ~= "string" then
		return nil
	end
	for _, config in TreeTypes.presets do
		if config.name:lower() == name:lower() then
			return config
		end
	end
	return nil
end

--- Returns a sorted list of preset names.
function TreeTypes.names()
	local list = {}
	for _, config in TreeTypes.presets do
		list[#list + 1] = config.name
	end
	table.sort(list)
	return list
end

--- Returns a random preset config.
function TreeTypes.pickRandom()
	local count = 0
	for _ in TreeTypes.presets do
		count += 1
	end
	local index = math.random(1, count)
	for _, config in TreeTypes.presets do
		index -= 1
		if index == 0 then
			return config
		end
	end
	return TreeTypes.presets.Oak
end

return TreeTypes
