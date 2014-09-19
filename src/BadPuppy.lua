-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

BadPuppy = {}
BadPuppy.changeDelay=10

-- Support code
function BadPuppy.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_RED.."BadPuppy".."> "..COLOR_END..msg;
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg );
end

BadPuppy.WorgenAbilities={
	["Running Wild"] = true,
	["Darkflight"] = true,
}

-- Event code
function BadPuppy.OnLoad()
	local _, race = UnitRace("player")
	if ( race == "Worgen" ) then
		BadPuppy.Print("BadPuppy!")
		BadPuppyFrame:RegisterEvent("UNIT_AURA");
		BadPuppyFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
		BadPuppyFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
	else
		BadPuppy.Print("Silly "..race..", you are not Worgen.");
		DisableAddOn("BadPuppy");
	end
	-- Preset MinMaxValues for ChangeTimeBar
	BadPuppy_ChangeTimeBar:SetMinMaxValues(0, BadPuppy.changeDelay);
	BadPuppy.playerName = GetUnitName("player")

end

function BadPuppy.OnUpdate()
	if (BadPuppy.canTransform and BadPuppy.isWorgenForm) then
		BadPuppy_ChangeTimeBar:SetValue(BadPuppy.canTransform - time() + 1)
		BadPuppy_ChangeTimeBar:Show()
	else
		BadPuppy_ChangeTimeBar:Hide()
	end
	if (BadPuppy.canTransform and BadPuppy.isWorgenForm and BadPuppy.canTransform<time())  then
		if IsMounted() then
			--BadPuppy.Print("Is Mounted.")
			BadPuppy.canTransform = nil
		else
			BadPuppy.Print("Transforming back to Human now: "..date("%H:%M:%S",time()))
			BadPuppyFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
			BadPuppy.isWorgenForm = nil
			BadPuppy.canTransform = nil
			DoEmote("ROAR")
			
			--CastSpellByName("Two Forms",1)
			--RunMacroText("/cast Two Forms")
		end
	end
end

-- Registered event code
function BadPuppy.UNIT_AURA(self, arg1)
--	BadPuppy.Print("arg1 = "..(arg1 or "nil"))
	if BadPuppy.inCombat then return end	-- don't scan if in combat
	BadPuppy.canTransform = BadPuppy.canTransform or (time() + BadPuppy.changeDelay)
	for i=1,40,1 do
		local name, _, icon, _, _, duration, _, caster = UnitBuff("player", i)
		if BadPuppy.WorgenAbilities[name] then
			--BadPuppy.Print("I have a worgen ability on")
			BadPuppy.canTransform = nil
			BadPuppy.isWorgenForm = true
			--BadPuppy.Print("Aura Name: "..(name or "nil"))
--		elseif name then
		end
	end
--	if BadPuppy.canTransform and BadPuppy.isWorgenForm then
--		BadPuppy.Print("I can change in "..(BadPuppy.canTransform - time()));
--	end

end

function BadPuppy.PLAYER_REGEN_DISABLED()
--	BadPuppy.Print("In Combat")
	BadPuppyFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	BadPuppy.inCombat = true
	BadPuppy.isWorgenForm = true
	BadPuppy.canTransform = nil
end

function BadPuppy.PLAYER_REGEN_ENABLED()
--	BadPuppy.Print("Out of Combat")
	BadPuppyFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	BadPuppy.inCombat = nil
	BadPuppy.canTransform = time() + BadPuppy.changeDelay
end

function BadPuppy.COMBAT_LOG_EVENT_UNFILTERED(event, ...)
	_, _, _, _, who, _, _, _, _, _, _, spellID = select(1, ...)
--	if spellID and (who == BadPuppy.playerName) then
--		BadPuppy.Print("SpellInfo: "..spellID..":"..(GetSpellInfo(spellID) or "not named"))
--	end
	if (who == BadPuppy.playerName) and (spellID == 68996) then  -- SpellID of "Two Forms"
		BadPuppy.isWorgenForm = not BadPuppy.isWorgenForm
		BadPuppyFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	end

end
