SWEP.Base = "weapon_tttbase"

SWEP.Spawnable = true
SWEP.AutoSpawnable = false
SWEP.AdminSpawnable = true

SWEP.HoldType = "pistol"

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/icon_sidekickdeagle.vmt")

	util.AddNetworkString("tttSidekickMSG")
	util.AddNetworkString("tttSidekickRefillCDReduced")
	util.AddNetworkString("tttSidekickDeagleRefilled")
	util.AddNetworkString("tttSidekickDeagleMiss")
else
	hook.Add("Initialize", "TTTInitSikiDeagleLang", function()
		LANG.AddToLanguage("English", "ttt2_weapon_sidekickdeagle_desc", "Shoot a player to make him your sidekick.")
		LANG.AddToLanguage("Deutsch", "ttt2_weapon_sidekickdeagle_desc", "Schieße auf einen Spieler, um ihn zu deinem Sidekick zu machen.")
	end)

	SWEP.PrintName = "Sidekick Deagle"
	SWEP.Author = "Alf21"

	SWEP.Slot = 7

	SWEP.ViewModelFOV = 54
	SWEP.ViewModelFlip = false

	SWEP.Category = "Deagle"
	SWEP.Icon = "vgui/ttt/icon_sidekickdeagle.vtf"
	SWEP.EquipMenuData = {
		type = "Weapon",
		desc = "ttt2_weapon_sidekickdeagle_desc"
	}
end

-- dmg
SWEP.Primary.Delay = 1
SWEP.Primary.Recoil = 6
SWEP.Primary.Automatic = false
SWEP.Primary.NumShots = 1
SWEP.Primary.Damage = 0
SWEP.Primary.Cone = 0.00001
SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = 1
SWEP.Primary.ClipMax = 1
SWEP.Primary.DefaultClip = 1

-- some other stuff
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.UseHands = true
SWEP.Kind = WEAPON_EXTRA
SWEP.CanBuy = {}
SWEP.LimitedStock = true
SWEP.globalLimited = true
SWEP.NoRandom = true

-- view / world
SWEP.ViewModel = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"
SWEP.Weight = 5
SWEP.Primary.Sound = Sound("Weapon_Deagle.Single")

SWEP.IronSightsPos = Vector(-6.361, -3.701, 2.15)
SWEP.IronSightsAng = Vector(0, 0, 0)

SWEP.notBuyable = true

local ttt2_sidekick_deagle_refill_conv = CreateConVar("ttt2_siki_deagle_refill", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
local ttt2_sidekick_deagle_refill_cd_conv = CreateConVar("ttt2_siki_deagle_refill_cd", 120, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
local ttt2_siki_deagle_refill_cd_per_kill_conv = CreateConVar("ttt2_siki_deagle_refill_cd_per_kill", 60, {FCVAR_NOTIFY, FCVAR_ARCHIVE})

local function SidekickDeagleRefilled(wep)
	if not IsValid(wep) then return end

	local text = LANG.GetTranslation("ttt2_siki_recharged")
	MSTACK:AddMessage(text)

	STATUS:RemoveStatus("ttt2_sidekick_deagle_reloading")
	net.Start("tttSidekickDeagleRefilled")
	net.WriteEntity(wep)
	net.SendToServer()
end

local function SidekickDeagleCallback(attacker, tr, dmg)
	if CLIENT then return end

	local target = tr.Entity

	--invalid shot return
	if not GetRoundState() == ROUND_ACTIVE or not IsValid(attacker) or not attacker:IsTerror() then return end

	--no/bad hit: (send message), start timer and return
	if not IsValid(target) or not target:IsTerror() or target:GetSubRole() == ROLE_JACKAL or target:GetSubRole() == ROLE_SIDEKICK then
		if IsValid(target) and (target:GetSubRole() == ROLE_JACKAL or target:GetSubRole() == ROLE_SIDEKICK) then
			attacker:PrintMessage(HUD_PRINTTALK, "You can't shoot a Jackal/Sidekick as Sidekick!")
		end	
		if ttt2_sidekick_deagle_refill_conv:GetBool() then
			net.Start("tttSidekickDeagleMiss")
			net.Send(attacker)
		end
		return
	end

	local deagle = attacker:GetWeapon("weapon_ttt2_sidekickdeagle")
	if IsValid(deagle) then
		deagle:Remove()
	end

	AddSidekick(target, attacker)

	net.Start("tttSidekickMSG")

	net.WriteEntity(target)

	net.Send(attacker)

	return true
end

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:ShootBullet(dmg, recoil, numbul, cone)
	cone = cone or 0.01
	
	local bullet = {}
	bullet.Num = 1
	bullet.Src = self:GetOwner():GetShootPos()
	bullet.Dir = self:GetOwner():GetAimVector()
	bullet.Spread = Vector(cone, cone, 0)
	bullet.Tracer = 0
	bullet.TracerName = self.Tracer or "Tracer"
	bullet.Force = 10
	bullet.Damage = 0
	bullet.Callback = SidekickDeagleCallback
	self:GetOwner():FireBullets(bullet)

	self.BaseClass.ShootBullet(self, dmg, recoil, numbul, cone)
end

function SWEP:OnRemove()
	if CLIENT then 
		STATUS:RemoveStatus("ttt2_sidekick_deagle_reloading") 
		timer.Stop("ttt2_sidekick_deagle_refill_timer")
	end
end

function ShootSidekick(target, dmginfo)
	local attacker = dmginfo:GetAttacker()

	if not attacker:IsPlayer() or not target:IsPlayer() or not IsValid(attacker:GetActiveWeapon())
		or not attacker:IsTerror() or not IsValid(target) or not target:IsTerror() then return end

	if target:GetSubRole() == ROLE_JACKAL or target:GetSubRole() == ROLE_SIDEKICK then
		attacker:PrintMessage(HUD_PRINTTALK, "You can't shoot a Jackal/Sidekick as Sidekick!")
		return
	end

	AddSidekick(target, attacker)

	net.Start("tttSidekickMSG")

	net.WriteEntity(target)

	net.Send(attacker)

end


if SERVER then
	hook.Add("PlayerDeath", "SidekickDeagleRefillReduceCD", function(victim, inflictor, attacker)
		if IsValid(attacker) and attacker:IsPlayer() and attacker:HasWeapon("weapon_ttt2_sidekickdeagle") and ttt2_sidekick_deagle_refill_conv:GetBool() then
			net.Start("tttSidekickRefillCDReduced")
			net.Send(attacker)	
		end
	end)
end


-- auto add sidekick weapon into jackal shop
hook.Add("LoadedFallbackShops", "SidekickDeagleAddToShop", function()
	if JACKAL and SIDEKICK and JACKAL.fallbackTable then
		AddWeaponIntoFallbackTable("weapon_ttt2_sidekickdeagle", JACKAL)
	end
end)

if CLIENT then
	hook.Add("TTT2FinishedLoading", "InitSikiMsgText", function()
		LANG.AddToLanguage("English", "ttt2_siki_shot", "Successfully shot {name} as Sidekick!")
		LANG.AddToLanguage("Deutsch", "ttt2_siki_shot", "Erfolgreich {name} als Sidekick geschossen!")

		LANG.AddToLanguage("English", "ttt2_siki_ply_killed", "Your Sidekick Deagle Cooldown was reduced by {amount} seconds.")
		LANG.AddToLanguage("Deutsch", "ttt2_siki_ply_killed", "Deine Sidekick Deagle Wartezeit wurde um {amount} Sekunden reduziert.")

		LANG.AddToLanguage("English", "ttt2_siki_recharged", "Your Sidekick Deagle has been recharged.")
		LANG.AddToLanguage("Deutsch", "ttt2_siki_recharged", "Deine Sidekick Deagle wurde wieder aufgefüllt.")
	end)

	hook.Add("Initialize", "ttt_sidekick_deagle_reloading", function() 
		STATUS:RegisterStatus("ttt2_sidekick_deagle_reloading", {
			hud = Material("vgui/ttt/hud_icon_deagle.png"),
			type = "bad"
		})
	end)

	net.Receive("tttSidekickMSG", function(len)
		local target = net.ReadEntity()

		if not target or not IsValid(target) then return end

		local text = LANG.GetParamTranslation("ttt2_siki_shot", {name = target:GetName()})
		MSTACK:AddMessage(text)
	end)

	net.Receive("tttSidekickRefillCDReduced", function()
		if not timer.Exists("ttt2_sidekick_deagle_refill_timer") or not LocalPlayer():HasWeapon("weapon_ttt2_sidekickdeagle") then return end
		
		local timeLeft = timer.TimeLeft("ttt2_sidekick_deagle_refill_timer") or 0
		local newTime = math.max(timeLeft - ttt2_siki_deagle_refill_cd_per_kill_conv:GetInt(), 0.1)
		local wep = LocalPlayer():GetWeapon("weapon_ttt2_sidekickdeagle")
		timer.Adjust("ttt2_sidekick_deagle_refill_timer", newTime, 1, function() SidekickDeagleRefilled(wep) end)

		if STATUS.active["ttt2_sidekick_deagle_reloading"] then
			STATUS.active["ttt2_sidekick_deagle_reloading"].displaytime = CurTime() + newTime
		end

		local text = LANG.GetParamTranslation("ttt2_siki_ply_killed", {amount = ttt2_siki_deagle_refill_cd_per_kill_conv:GetInt()})
		MSTACK:AddMessage(text)
		chat.PlaySound()
	end)

	net.Receive("tttSidekickDeagleMiss", function()
		local client = LocalPlayer()
		if not IsValid(client) or not client:IsTerror() or not client:HasWeapon("weapon_ttt2_sidekickdeagle") then return end

		local wep = client:GetWeapon("weapon_ttt2_sidekickdeagle")
		local initialCD = ttt2_sidekick_deagle_refill_cd_conv:GetInt()

		STATUS:AddTimedStatus("ttt2_sidekick_deagle_reloading", initialCD, true) 
		timer.Create("ttt2_sidekick_deagle_refill_timer", initialCD, 1, function()
			SidekickDeagleRefilled(wep)
		end)	
	end)
else
	net.Receive("tttSidekickDeagleRefilled", function()
		local wep = net.ReadEntity()
		if IsValid(wep) then
			wep:SetClip1(1)
		end
	end)
end
