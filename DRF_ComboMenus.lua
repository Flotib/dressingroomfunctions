--
--    Dressing Room Functions - Allows undress and target model for dressing room
--    Copyright (C) 2018  Rachael Alexanderson
--
-- Redistribution and use in source and binary forms, with or without modification, are permitted provided
-- that the following conditions are met:
-- 
-- 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
-- disclaimer.
-- 
-- 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
-- disclaimer in the documentation and/or other materials provided with the distribution.
-- 
-- 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
-- derived from this software without specific prior written permission.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
-- BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
-- EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
-- PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
-- TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--

if not ( DRF_Version == DRF_CoreVersion ) then
	return;
end

local DressUpModel = DressUpFrame.ModelScene:GetPlayerActor();

-- Popup Box for Whisper
local editboxtext;
StaticPopupDialogs["DRF_WhisperTarget"] = {
	text = DRF_L["WhisperTarget"],
	button1 = DRF_L["Whisper"],
	button2 = DRF_L["Cancel"],
	button3 = DRF_L["Target"],
	hasEditBox = 1,
	whileDead = 1,
	hideOnEscape = 1,
	timeout = 0,
	EditBoxOnTextChanged = function (self, data)		-- careful! 'self' here points to the editbox, not the dialog
		if (self:GetText() ~= "") then
			self:GetParent().button1:Enable();	-- self:GetParent() is the dialog
		else
			self:GetParent().button1:Disable();
		end
	end,
	OnShow = function(self,...)
		self.button1:Disable();
	end,
	OnAccept = function(self,...)
		editboxtext = self.editBox:GetText();
		DRF_DumpItemLinks("whisper",editboxtext);
	end,
	OnCancel = function() end,
	OnAlt = function(self,...)
		DRF_DumpItemLinks("whisper","target");
	end,
	enterClicksFirstButton = 1,
	preferredIndex = 3,	-- avoid some UI taint
}

-- Use No-Taint library - I know this looks weird but this is the way I prefer to do it
local UIDropDownMenu_Initialize = Lib_UIDropDownMenu_Initialize;
local UIDropDownMenu_CreateInfo = Lib_UIDropDownMenu_CreateInfo;
local UIDropDownMenu_AddButton = Lib_UIDropDownMenu_AddButton;
local ToggleDropDownMenu = Lib_ToggleDropDownMenu;
local CloseDropDownMenus = Lib_CloseDropDownMenus;

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
	[24] = "Pandaren",
	[27] = "Nightborne",
	[28] = "HighmountainTauren",
	[29] = "VoidElf",
	[30] = "LightforgedDraenei",
	[31] = "ZandalariTroll",
	[32] = "KulTiranHuman",
	[34] = "DarkIronDwarf",
	[36] = "MagharOrc",
};

-- _raceList is the content-reference table for the background list.
local _raceList = { };
for x, name in ipairs(_backgroundList) do
	_raceList[name] = x;
end

local DRF_button1 = CreateFrame("Button","DRF_UndressButton",DressUpFrame,"UIPanelButtonTemplate");
local DRF_button2 = CreateFrame("Button","DRF_TargetButton",DressUpFrame,"UIPanelButtonTemplate");

local function DRF_HookedUpdate(self, delta)
	if ( not DRF_UndressQueued ) then return; end
	DRF_TimeLeft = DRF_TimeLeft - delta;
	if ( DRF_TimeLeft <=0 ) then
		DRF_DoUndress(1);
		DRF_UndressQueued = nil;
	end
end
--DressUpModel:HookScript("OnUpdate",DRF_HookedUpdate);

function DRF_DoUndress(NoTimer)
	DressUpModel = DressUpFrame.ModelScene:GetPlayerActor();
	DressUpModel:Undress();
	-- This function is implemented to hide the default "swim suits" for people who
	-- do not want to see them. This would be useful with the auto-undress function
	-- for people who play a character gender that they'd rather not see with only
	-- the "bare necessities" all the time. And besides, most male characters have
	-- really ugly underwear, anyhow!
	-- EDIT: Well, the underwear really improved a LOT in Warlords with the new models. Kudos, Blizzard!

	if ( DRF_Global["Conservative"] ) then
		-- White Tuxedo Shirt
		DressUpModel:TryOn(select(2,GetItemInfo(6833)));
		-- Black Tuxedo Pants
		DressUpModel:TryOn(select(2,GetItemInfo(6835)));
		-- Brightwood Sandals
		DressUpModel:TryOn(select(2,GetItemInfo(55726)));
	end
	if not NoTimer then
		DRF_UndressQueued = 1;
		DRF_TimeLeft = 1.25;
	end
	if ( DRF_LastQueuedItem ~= nil ) then
		DressUpModel:TryOn(DRF_LastQueuedItem);
	end
end

DRF_button1:SetPoint("Center",DressUpFrame,"BottomLeft",212,15); -- coords if not using BetterWardrobe which changed how the "link" button looks and its position
DRF_button1:SetSize(108,22);
DRF_button1.text = _G["DRF_UndressButton"];
DRF_button1.text:SetText(DRF_L["Undress"]);
DRF_button1:SetScript("OnClick",function(self,event,arg1)
	DRF_LastQueuedItem = nil;
	DRF_DoUndress(1);
	-- we're removing the "PlaySound" for now. if Blizzard wants to make this needlessly more complicated... sadface. Really, Blizzard? Come on!
	PlaySoundFile("gsTitleOptionOK");
end);

DRF_button2:SetPoint("Center",DRF_UndressButton,"Center",82,0); -- coords if not using BetterWardrobe which changed how the "link" button looks and its position
DRF_button2:SetSize(60,22);
DRF_button2.text = _G["DRF_TargetButton"];
DRF_button2.text:SetText(DRF_L["Target"]);
DRF_button2:SetScript("OnClick",function(self,event,arg1)
	local race, fileName = UnitRace("target");
	DressUpModel = DressUpFrame.ModelScene:GetPlayerActor();

	if ( UnitIsPlayer("target") ) then
		DressUpModel:SetModelByUnit("target", false, true);
		DRF_DumpItemLinks("precache"); -- Precache item links
		DRF_LastGender = UnitSex("target");
		DRF_LastRace = select(2,UnitRace("target"));
		DRF_LastName = UnitName("target");
		--SetDressUpBackground(DressUpFrame, fileName);
	else
		race, fileName = UnitRace("player");
		DressUpModel:SetModelByUnit("player", false, true);
		DRF_LastGender = UnitSex("player");
		DRF_LastRace = select(2,UnitRace("player"));
		DRF_LastName = UnitName("player");
		--SetDressUpBackground(DressUpFrame, fileName);
	end
	DRF_LastQueuedItem = nil;
	if ( DRF_Global["UndressTarget"] ) then
		DRF_DoUndress();
	end
	PlaySoundFile("gsTitleOptionOK");
end);
