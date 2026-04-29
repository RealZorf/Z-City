local CLASS = player.RegClass("Vortigaunt")

local model = "models/player/vortigaunt.mdl"
local vortNames = {
	"Va", "Zuun", "Keth", "Ruun", "Sha", "Naar", "Vek", "Thal", "Uun", "Kael",
	"Zeth", "Vraal", "Niir", "Suun", "Koss", "Rael", "Duun", "Maar", "Vel", "Tuun",
	"Xuun", "Kraal", "Sethar", "Vuun", "Neth", "Zaal", "Reth", "Orr", "Kuun", "Shael",
	"Vorr", "Taln", "Neer", "Zorr", "Ural", "Ka", "Shaal", "Veth", "Ruunak", "Kelth"
}

function CLASS.Off(self)
	if CLIENT then return end

	self:SetNetVar("Accessories", "")
	self:SetNWString("PlayerRole", "")
	self:SetNWString("PlayerName", "")
end

CLASS.NoGloves = true
CLASS.CanUseDefaultPhrase = true
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = true

function CLASS.On(self)
	if CLIENT then return end

	if IsValid(self.FakeRagdoll) then
		hg.FakeUp(self, nil, nil, true)
	end

	self:SetModel(model)
	self:SetSubMaterial()
	self:SetSkin(0)
	self:SetBodyGroups("")
	self:SetNetVar("Accessories", "")
	self.CurAppearance = nil

	if zb.GiveRole then
		zb.GiveRole(self, "Vortigaunt", Color(110, 220, 150))
	end

	self:SetNWString("PlayerRole", "Vortigaunt")
	self:SetNWString("PlayerName", table.Random(vortNames))
end

return CLASS
