DRF_CoreVersion = "v1.4.3";
--
--    Dressing Room Functions - Allows undress and target model for dressing room
--    Copyright (C) 2016  Rachael Alexanderson
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

local function SysMessage(text)
	DEFAULT_CHAT_FRAME:AddMessage(DRF_L["S_DRF"]..text);
end

local function Noop() end

local _backgroundList = {
	[1] = "Human",
	[2] = "Orc",
	[3] = "Dwarf",
	[4] = "NightElf",
	[5] = "Scourge",
	[6] = "Tauren",
	[7] = "Gnome",
	[8] = "Troll",
	[9] = "Goblin",
	[10] = "BloodElf",
	[11] = "Draenei",
	[22] = "Worgen",
	[24] = "Pandaren"
};

-- _raceList is the content-reference table for the background list.
local _raceList = { };
for x, name in ipairs(_backgroundList) do
	_raceList[name] = x;
end

DRF_Version = GetAddOnMetadata("DressingRoomFunctions","Version");
DRF_DebugMode = false;

function DRF_ImproperUpdate()
	if not (DRF_L) then
		message("You have not properly updated your add-ons. Please restart the game - Dressing Room Functions will not work until you do.");
	else
		message(DRF_L["BadUpdate"]);
	end
	DEFAULT_CHAT_FRAME:AddMessage(DRF_L["BadUpdate"]);
end

if not ( DRF_Version == DRF_CoreVersion ) then
	DRF_ImproperUpdate();
	return;
end

local function DressUpTexturePath(raceFileName)
	-- HACK
	if ( not raceFileName ) then
		raceFileName = "Orc";
	end
	-- END HACK

	return "Interface\\DressUpFrame\\DressUpBackground-"..raceFileName;
end

local function SetDressUpBackground(frame, fileName)
	local texture = DressUpTexturePath(fileName);
	
	if ( frame.BGTopLeft ) then
		frame.BGTopLeft:SetTexture(texture..1);
	end
	if ( frame.BGTopRight ) then
		frame.BGTopRight:SetTexture(texture..2);
	end
	if ( frame.BGBottomLeft ) then
		frame.BGBottomLeft:SetTexture(texture..3);
	end
	if ( frame.BGBottomRight ) then
		frame.BGBottomRight:SetTexture(texture..4);
	end
end

function DressUpItemLink(link)
	if ( not link or not IsDressableItem(link) ) then
		return false;
	end
	DRF_LastQueuedItem = link;
	if ( SideDressUpFrame.parentFrame and SideDressUpFrame.parentFrame:IsShown() ) then
		if ( not SideDressUpFrame:IsShown() or SideDressUpFrame.mode ~= "player" ) then
			SideDressUpFrame.mode = "player";
			SideDressUpFrame.ResetButton:Show();

			local race, fileName = UnitRace("player");
			SetDressUpBackground(SideDressUpFrame, fileName);

			ShowUIPanel(SideDressUpFrame);
			SideDressUpModel:SetUnit("player");

			-- We'll worry more about this later. For now, we're just
			-- copying a function. (Oh my god, UGH, the humanity!)
			if ( DRF_Global["AutoUndress"] ) then
				SideDressUpModel:Undress();
				if ( DRF_Global["Conservative"] ) then
					SideDressUpModel:TryOn(select(2,GetItemInfo(6833)));
					SideDressUpModel:TryOn(select(2,GetItemInfo(6835)));
					SideDressUpModel:TryOn(select(2,GetItemInfo(55726)));
				end

			end
		end
		SideDressUpModel:TryOn(link);
	else
		if ( not DressUpFrame:IsShown() or DressUpFrame.mode ~= "player") then
			DressUpFrame.mode = "player";
			DressUpFrame.ResetButton:Show();

			local race, fileName = UnitRace("player");
			SetDressUpBackground(DressUpFrame, fileName);

			ShowUIPanel(DressUpFrame);
			DressUpModel:SetUnit("player");
			DRF_LastGender = UnitSex("player");
			DRF_LastRace = select(2,UnitRace("player"));
			DRF_LastName = UnitName("player");

			if ( DRF_Global["OpenToTarget"] ) then
				DRF_TargetButton:Click();
			end

			if ( DRF_Global["AutoUndress"] ) then
				DRF_DoUndress(1);
			end
		end
		DressUpModel:TryOn(link);
	end
	return true;
end

function DRF_DumpItemLinks(dest,arg1)
	local whisperTarget;
	-- Reference Table - created with user's language
	local LanguageRefs = { DRF_L["Head"], DRF_L["Shoulder"], DRF_L["Back"], DRF_L["Chest"], DRF_L["Shirt"], DRF_L["Tabard"],
		DRF_L["Wrist"], DRF_L["Hands"], DRF_L["Waist"], DRF_L["Legs"], DRF_L["Feet"], DRF_L["MainHand"], DRF_L["OffHand"] };

	-- Slot ID table - with LUA quirks this somehow works, may not be future proof? Well it works now, so, whatever!
	local SlotIDs = { GetInventorySlotInfo("HeadSlot"), GetInventorySlotInfo("ShoulderSlot"), GetInventorySlotInfo("BackSlot"),
		GetInventorySlotInfo("ChestSlot"), GetInventorySlotInfo("ShirtSlot"), GetInventorySlotInfo("TabardSlot"), 
		GetInventorySlotInfo("WristSlot"), GetInventorySlotInfo("HandsSlot"), GetInventorySlotInfo("WaistSlot"),
		GetInventorySlotInfo("LegsSlot"), GetInventorySlotInfo("FeetSlot"), GetInventorySlotInfo("MainHandSlot"),
		GetInventorySlotInfo("SecondaryHandSlot") };

	local mog, preview; -- MogIt support
	if ( arg1 == "target" ) then
		whisperTarget = GetUnitName("target",true);
	else
		whisperTarget = arg1;
	end
	if ( arg1 == nil and dest == "whisper" ) then
		SysMessage(DRF_L["InvalidTarget"]);
		return;
	end
	-- Iterate the Language table for each slot, and then print out its link.
	if ( dest == "chat" or dest == "whisper" ) then
		local GenderMessage;
		local RaceMessage;
		-- Localize the player's gender and race
		if ( DRF_LastGender == 2 ) then 
			GenderMessage = MALE;
			RaceMessage = DRF_L[DRF_LastRace.."M"];
		else
			GenderMessage = FEMALE;
			RaceMessage = DRF_L[DRF_LastRace.."F"];
		end
		-- Show the player's name and physical info. We're not 100% certain on this, but we're going by data we have.
		if ( dest == "chat" ) then
			SysMessage(DRF_L["Links"].." (|cffff9090"..DRF_LastName.."|r - |cffff90ff"..GenderMessage.." |cff90ff90"..RaceMessage.."|r):");
		elseif ( dest == "whisper" ) then
			SendChatMessage("<DressingRoomFunctions> ("..DRF_LastName.." - "..GenderMessage.." "..RaceMessage.."):","WHISPER","",whisperTarget);
		end
	elseif ( dest == "mogit" ) then
		-- This uses some modified code from MogIt. (Used with permission)
		-- It initializes a preview window and sets the player race as if coming from a [MogIt] link.

		-- This will access the MogIt addon's private namespace
		mog=_G["MogIt"];

		-- Get an available preview window. By default, MogIt will create a new one, depending on the user's settings.
		preview = mog:GetPreview();

		-- Set the preview window's race and gender to match DRF's, even if DRF's target is a player other than the user.
		preview.data.displayRace = _raceList[DRF_LastRace];
		preview.data.displayGender = DRF_LastGender - 2;

		-- Hacks. Because without which, for whatever reason, it just doesn't work.
		if ( DRF_LastRace == "Worgen" ) then
			preview.data.displayRace = 22;
		elseif ( DRF_LastRace == "Pandaren" ) then
			preview.data.displayRace = 24;
		end

		-- We're not going to bother with weapon enchants. (For now) This may be implemented in the future.
		preview.data.weaponEnchant = 0;

		-- Tell MogIt to reset and initialize the preview model to the data we sent.
		preview.model:ResetModel();
		preview.model:Undress();
	end
	for i,v in ipairs(LanguageRefs) do
		local myItemLink = select(6,C_TransmogCollection.GetAppearanceSourceInfo(DressUpModel:GetSlotTransmogSources(SlotIDs[i])));
		if ( myItemLink ~= nil ) then
			if ( dest == "chat" ) then
				-- Links the item in the chat window.
				SysMessage(v..": "..myItemLink);
			elseif ( dest == "whisper" ) then
				-- Links the item to the whisper target.
				SendChatMessage(v..": "..myItemLink,"WHISPER","",whisperTarget);				
			elseif ( dest == "mogit" ) then
				-- Links the item directly to MogIt's latest preview window.
				mog:AddToPreview(myItemLink, preview);
			end
		end
	end
end

function OpenDressingRoom()
	if ( not DressUpFrame:IsShown() or DressUpFrame.mode ~= "player") then
		DressUpFrame.mode = "player";
		DressUpFrame.ResetButton:Show();

		local race, fileName = UnitRace("player");
		SetDressUpBackground(DressUpFrame, fileName);

		ShowUIPanel(DressUpFrame);
		DressUpModel:SetUnit("player");
		DRF_LastGender = UnitSex("player");
		DRF_LastRace = select(2,UnitRace("player"));
		DRF_LastName = UnitName("player");
		DRF_DumpItemLinks("precache"); -- Precache item links

		if ( DRF_Global["OpenToTarget"] ) then
			DRF_TargetButton:Click();
		end

		if ( DRF_Global["AutoUndress"] ) then
			DRF_DoUndress(1);
		end
	else
		HideUIPanel(DressUpFrame);
	end
end

-- /dr command to open dressing room. That's all it does!
SLASH_OPENDR1, SLASH_OPENDR2 = '/dressingroom', '/dr';
function SlashCmdList.OPENDR(msg, editBox)
	OpenDressingRoom();
end

-- Debugging function for mogit. Decodes race, gender, etc, from a chat link.
function DRF_DebugMogit(arg)
	return _G["MogIt"]:LinkToSet(arg);
end

-- Global Precache. This 'should' ensure certain items (used by this addon) are always loaded.
local preCache;
preCache = GetItemInfo(23323);
preCache = GetItemInfo(6833);
preCache = GetItemInfo(6835);
preCache = GetItemInfo(55726);
preCache = GetItemInfo(4314);
