local firstTimeChk = false;
local startTime = 0;
local currentTime = 0;
local elapsedTime = 0;
local expArray = {};
local timeArray = {};
local timeBinMins = 1;
local timeBinning = timeBinMins*60;
local currentBin = 0;
local displayArray = {};
local displayDebuffArray = {5,15,30,60,90,120};
local TextLineArray = {};
local TextLineLabelArray = {};
local OldExp = 0;
local statusArray = {};
local debuffArray = {};
local enabled = true;
local alreadyWarned = {};
local alreadyWarnedMissing = {};
local approvedDebuffs = {
,"Expose Weakness"
,"Faerie Fire (Feral)"
,"Faerie Fire"
,"Gift of Arthas"
,"Hunter's Mark"
,"Sunder Armor"
,"Curse of Recklessness"
,"Curse of the Elements"
,"Curse of Shadow"


,"Winter's Chill"
,"Shadow Word: Pain"
,"Mind Flay"
,"Shadow Weaving"

,"Screech"
,"Demoralizing Shout"

,"Thunderfury"
,"Shadow Vulnerability"
,"Spell Vulnerability"
,"Shadowburn"

,"Deep Wound"
,"Taunt"
,"Growl"
,"Challenging Shout"

,"Corruption"
,"Curse of Agony"
};
local debuffNamesArray = {}
local mobNames = {"Razorgore the Untamed","Vaelastrasz the Corrupt","Broodlord Lashlayer","Firemaw","Ebonroc","Flamegor","Chromaggus","Nefarian"
,"Lucifron","Magmadar","Gehennas","Garr","Shazzrah","Baron Geddon","Golemagg the Incinerator","Sulfuron Harbinger","Majordomo Executus","Ragnaros"
}
local missingToggle = false;


local mobSpecificUnapprovedDebuffs = { ["Broodlord Lashlayer"] = {"Curse of Recklessness"} }
local mobSpecificApprovedDebuffs = { ["Chromaggus"] = {"Detect Magic"} }


function createDebuffFrame()
	backgroundFrame = CreateFrame("SimpleHTML");
	backgroundFrame:Raise()
	backgroundFrame:SetBackdropColor(0,0,0,1);
	backgroundFrame:SetFont('Fonts\\FRIZQT__.TTF', 11);
	backgroundFrame:SetWidth(160)
	backgroundFrame:SetHeight(tonumber(#displayDebuffArray+1)*16)
	backgroundFrame:SetPoint("TOPRIGHT",UIParent)
	backgroundFrame:SetFrameStrata("FULLSCREEN_DIALOG")
	backgroundFrame:Show();
	
	debuffArray[0] = backgroundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	debuffArray[0]:SetPoint("TOPLEFT",backgroundFrame,1,0)
	debuffArray[0]:SetText("Debuffs");
	
	for i=1,16 do
		debuffArray[i] = backgroundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		debuffArray[i]:SetPoint("TOPLEFT",backgroundFrame,1,-15*i)
		debuffArray[i]:SetText("-");
		debuffArray[i]:SetTextColor(0,0,0);
	end

	
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function updateDebuffFrameColor(num, debuffName, charName)
	if debuffName == "-" then
		debuffArray[num]:SetTextColor(0,0,0);
		return
	end
	
	approvedDebuffsTemp = approvedDebuffs
	
	if debuffName == "Spell Vulnerability" then
		msg = "Nightfall proc'd! Spell Vulnerability detected! applied by: "..charName
		if not alreadyWarned[debuffName..charName] then
			SendChatMessage(msg ,"YELL");
			alreadyWarned[debuffName..charName] = 1
			C_Timer.After(10, function() resetWarningTimer(debuffName,charName) end)
		end
	end

	local mobName = UnitName("target")
	if not mobName then
		return
	end
	if not has_value(mobNames,mobName) then
		return
	end
	if
	if has_value(mobSpecificUnapprovedDebuffs,mobName) then
		unapprovedTable = mobSpecificUnapprovedDebuffs[mobName]
		for key,value in pairs(unapprovedTable) do
			approvedDebuffsTemp[key] = nil
		end
	end
	if has_value(mobSpecificApprovedDebuffs,mobName) then
		approvedTable = mobSpecificApprovedDebuffs[mobName]
		for key,value in pairs(approvedTable) do
			table.insert(approvedDebuffsTemp,value)
		end
	end
	

	if has_value(approvedDebuffsTemp,debuffName) then
		debuffArray[num]:SetTextColor(0,1,0);
	else
		msg = "Unapproved debuff detected '"..debuffName.."', applied by: "..charName
		if not alreadyWarned[debuffName..charName] then
			SendChatMessage(msg ,"RAID");
			alreadyWarned[debuffName..charName] = 1
			C_Timer.After(30, function() resetWarningTimer(debuffName,charName) end)
		else
			if alreadyWarned[debuffName..charName] == 0 then
				SendChatMessage(msg ,"RAID");
				alreadyWarned[debuffName..charName] = 1
				C_Timer.After(30, function() resetWarningTimer(debuffName,charName) end)
			end
		end
		debuffArray[num]:SetTextColor(1,0,0);
	end	
end

function resetWarningTimer(debuffName,charName)
	--print("resetWarningTimer - callback")
	alreadyWarned[debuffName..charName] = 0
end

function resetMissingWarningTimer(debuffName,charName)
	--print("resetWarningTimer - callback")
	alreadyWarnedMissing[debuffName] = 0
end

function isempty(s)
  return s == nil or s == ''
end

function updateDebuffFrame()
	if not enabled then
		return
	end
	
	local mobName = UnitName("target")
	if not mobName then
		return
	end
	if not has_value(mobNames,mobName) then
		return
	end
	
	for i=1,16 do
	  local debuffName,_,_,_,_,_,source  = UnitDebuff("target", i)

	  if debuffName then
		debuffNamesArray[i] = debuffName
		debuffArray[i]:SetText(debuffName)
		updateDebuffFrameColor(i,debuffName,GetUnitName(source))
	  else
		debuffNamesArray[i] = "-"
		debuffArray[i]:SetText("-");
		updateDebuffFrameColor(i,"-","")
	  end
	end
	-- I AM DRUNK DONT JUDGE MY CODING
	if missingToggle then
		for i=1,16 do
			--print("debuffNamesArray[i]"..debuffNamesArray[i])
			--print("approvedDebuffs[i]: "..approvedDebuffs[i])
			if not has_value(debuffNamesArray, approvedDebuffs[i]) then
				debuffName = approvedDebuffs[i]
				msg = "Missing debuff detected '"..debuffName
				if not alreadyWarnedMissing[debuffName] then
					SendChatMessage(msg ,"RAID");
					alreadyWarnedMissing[debuffName] = 1
					C_Timer.After(30, function() resetMissingWarningTimer(debuffName) end)
				else
					if alreadyWarnedMissing[debuffName] == 0 then
						SendChatMessage(msg ,"RAID");
						alreadyWarnedMissing[debuffName] = 1
						C_Timer.After(30, function() resetMissingWarningTimer(debuffName) end)
					end
				end
			
			end
		end
	end
end

createDebuffFrame();
SLASH_DEBUFF_WATCHER1 = "/debuffWatcher";
SlashCmdList["DEBUFF_WATCHER"] = function(msg)

	if msg == "disable" then
		enabled = false
	end
	if msg == "enable" then
		enabled = true
	end
	if msg == "missingToggle" then
		if missingToggle == true then
			missingToggle = false
		else
			missingToggle = true
		end
	end
	if msg == ""
		then
			DEFAULT_CHAT_FRAME:AddMessage("=============================================", 0.3, 1.0, 0.0);
			DEFAULT_CHAT_FRAME:AddMessage("debuffWatcher information", 0.0, 1.0, 0.0);
			DEFAULT_CHAT_FRAME:AddMessage("/debuffWatcher disable", 0.0, 1.0, 0.0);
			DEFAULT_CHAT_FRAME:AddMessage("/debuffWatcher enable", 0.0, 1.0, 0.0);
			DEFAULT_CHAT_FRAME:AddMessage("/debuffWatcher missingToggle", 0.0, 1.0, 0.0);
			DEFAULT_CHAT_FRAME:AddMessage("=============================================", 0.3, 1.0, 0.0);
		end

end

local debuffWatcherFrame = CreateFrame("Frame")
debuffWatcherFrame:RegisterEvent("ADDON_LOADED")
debuffWatcherFrame:RegisterEvent("COMBAT_LOG_EVENT")
debuffWatcherFrame:SetScript("OnEvent", function (self, event, arg1)

	if event == "ADDON_LOADED" and arg1 == "debuffWatcher" then
		C_Timer.NewTicker(0.9, function()
			updateDebuffFrame();
		end);

	end
	updateDebuffFrame();
	

end)
