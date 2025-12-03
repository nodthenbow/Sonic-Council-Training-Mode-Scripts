--This is a frame data visualizer for Sokkou Seitokai - Sonic Council for Bizhawk 2.10
--[[
Folder name: "Sokkou Seitokai - Sonic Council (Japan)"
SHA256 checksum for data and names: e2394185d08792923044f912a263e71e7ca5d3a8f7bad234214a98ae74dd6490-00000009
]]
--If it works on future versions, cool. If not, I'm probably not going to update it.

--[[
known issues:
	none
--]]
--the once loaded stuff

local p1Base = 0x0DBA00
local p2Base = 0x0DBB3C
local fbArrayBase = 0x0dbcf0
local numHitboxes = 0
local activeHitboxBase = 0
local fireballOnScreen = 0
local p1fbActive = 0
local p2fbActive = 0
local fbDraw = 0 --fireballs for both because they are all stored on the same table 
local fbNotActive = 0

--colours
local lightGreen = 0xff00c000 --hurtbox
local lightGreenBG = 0xff00c000
local lightRed = 0xffff0000 --hitbox
local lightRedBG = 0xffff0000
local white = 0xffffffff --currently invuln (based on flag, some invuln stuff just have no hurtboxes)
local whiteBG = 0xffffffff
local yellow = 0xffffff00 --pushbox/not actionable
local yellowBG = 0xffffff00
local purple = 0xffff00ff --fireball
local purpleBG = 0xffff00ff
local blue = 0xff0000ff --throw
local blueBG = 0xff0000ff
local black = 0xff000000 --nothing/screen freeze (also used to blank the next box)
local blackBG = 0xff101010


local p1Actionable = 0
local p2Actionable = 0
local noActionCount = 3
--determines for how long after both players stop taking actions do you update the bar
local maxNoAction = 3 --should be at least 2 due to how the game handles the actionable flags we use
local noActionBlankBarCount = 30
local noActionBlankBarTimeout = 30
local noActionBlankBarFlag = 0

local fdbIndex = 0
local p1fdb = {}
local p1fdbbg = {}
local p2fdb = {}
local p2fdbbg = {}

for i=0, 39 do
	p1fdb[i] = black
	p2fdb[i] = black
	p1fdbbg[i] = blackBG
	p2fdbbg[i] = blackBG
end
local p1CurrBoxColour = black
local p1CurrBoxColourBG = blackBG

local p2CurrBoxColour = black
local p2CurrBoxColourBG = blackBG


--the once per frame stuff
--memory default is work ram high (starts at 0x06000000)
while true do
	emu.frameadvance();
	if memory.read_u8(0xdbef8) == 4 then
	
		fireballOnScreen = 0
		p1fbActive = 0
		p2fbActive = 0
		fbDraw = 0 --fireballs for both because they are all stored on the same table 
		fbNotActive = 0
		for i = 0, 15, 1 do --recheck this at some point, it might be 17 long 
			fbDraw = memory.read_u8(fbArrayBase + (i*0x10))
			fbDraw = fbDraw / 64 --matches the in game logic that determines if a fb is active
			fbNotActive = memory.read_u8(fbArrayBase + 2+(i*0x10))
			if fbDraw >= 2 and fbNotActive ~= 1 then --game checks for floor(fbDraw)>1
				fireballOnScreen = 1
				if i < 8 then
					p1fbActive = 1
				else
					p2fbActive = 1
				end
			end
		end
		p1Actionable = memory.read_u8(0xdba5d) --flag that is true if the character is actionable
		p2Actionable = memory.read_u8(0xdbb99) --same flag but for p2 (the offset is 0x13c, same as most stuff)
		
		if p1Actionable == 1 and p2Actionable == 1 and fireballOnScreen == 0 then
			noActionCount = noActionCount + 1
			--increment the index so we start after the blank
			if noActionCount == maxNoAction then fdbIndex = fdbIndex + 1 end
			--stops the scroll from updating
			if noActionCount > maxNoAction then noActionCount = maxNoAction end 
			--I want the bar to blank itself if nothing happens for a while
			noActionBlankBarCount = noActionBlankBarCount + 1
			if noActionBlankBarCount > noActionBlankBarTimeout then 
				noActionBlankBarCount = noActionBlankBarTimeout
				noActionBlankBarFlag = 1 --sets the flag so we blank the bar before the next action
			end
		else
			noActionCount = 0 --if either player isn't actionable the counts are reset
			noActionBlankBarCount = 0 
			if noActionBlankBarFlag == 1 then --if the flag is set blank the bar
				for i=0, 39 do
					p1fdb[i] = black
					p2fdb[i] = black
					p1fdbbg[i] = blackBG
					p2fdbbg[i] = blackBG
				end
				fdbIndex = 39 --this will get incremented to 0 since we set noActionCount to 0
				noActionBlankBarFlag = 0
			end
		end
		if noActionCount < maxNoAction then
			fdbIndex = fdbIndex + 1 --if we aren't 
			if fdbIndex > 39 then fdbIndex = 0 end
		end
		
		--have the default colour be yellow so inactionable frames are yellow by default
		p1CurrBoxColour = yellow
		p1CurrBoxColourBG = yellowBG
		p2CurrBoxColour = yellow
		p2CurrBoxColourBG = yellowBG
		
		
		if p1Actionable == 1 then
			p1CurrBoxColour = lightGreen
			p1CurrBoxColourBG = lightGreenBG
		end
		if p2Actionable == 1 then
			p2CurrBoxColour = lightGreen
			p2CurrBoxColourBG = lightGreenBG
		end
		
		
		if memory.read_s8(p1Base+0x59) == 1 then --invuln flag p1
			p1CurrBoxColour = white
			p1CurrBoxColourBG = whiteBG
		end
		if memory.read_s8(p1Base+0x59+0x13c) == 1 then --invuln flag p2 (p2base is p1base+0x13c)
			p2CurrBoxColour = white
			p2CurrBoxColourBG = whiteBG
		end
		
		
		if memory.read_s8(0x0dba83) ~= 0 then --p1 throw active flag 
			p1CurrBoxColourBG = blueBG --only want inner colour to change
		end
		if memory.read_s8(0x0dba83+0x13c) ~= 0 then --p2 throw active flag 
			p2CurrBoxColourBG = blueBG
		end
		
		
		numHitboxes = memory.read_s8(p1Base+0x67) --hitboxes for p1
		activeHitboxBase = 0x0dbc80  
		for i = 0, numHitboxes-1, 1 do
			if memory.read_u8(0x0DBA66) == 0 then break end
			p1CurrBoxColourBG = lightRedBG
		end
		
		numHitboxes = memory.read_s8(p2Base+0x67) --hitboxes for p2
		activeHitboxBase = 0x0dbca0
		for i = 0, numHitboxes-1, 1 do
			if memory.read_u8(0x0DBA66+0x13c) == 0 then break end
			p2CurrBoxColourBG = lightRedBG
		end
		
		
		--we checked if fireballs were active at the top already
		if p1fbActive == 1 then p1CurrBoxColourBG = purpleBG end
		
		if p2fbActive == 1 then p2CurrBoxColourBG = purpleBG end
		
		
		if memory.read_u8(0xdbdf6) == 1 then --screen freeze flag
			p1CurrBoxColour = black
			p2CurrBoxColour = black
		end
		
		
		--drawing the bar stuff
		--first if we are at the timeout we blank the bar
		
		
		
		--set the colours in the frame data box arrays and blank the next one 
		if noActionCount < maxNoAction then 
			p1fdb[fdbIndex] = p1CurrBoxColour
			p1fdbbg[fdbIndex] = p1CurrBoxColourBG
			p2fdb[fdbIndex] = p2CurrBoxColour
			p2fdbbg[fdbIndex] = p2CurrBoxColourBG
			if fdbIndex == 39 then 
				p1fdb[0] = black
				p1fdbbg[0] = blackBG
				p2fdb[0] = black
				p2fdbbg[0] = blackBG
			else 
				p1fdb[fdbIndex+1] = black
				p1fdbbg[fdbIndex+1] = blackBG
				p2fdb[fdbIndex+1] = black
				p2fdbbg[fdbIndex+1] = blackBG
			end
		end
		
		--the screen is 328 pixels wide and 238 pixels tall
		--want the boxes to be 5x5 with a 1px gap between them (7px wide per)
		--bar is 240px-1 long
		for i=0, 39 do
			--p1 line
			gui.drawRectangle(
			25+i*7,
			40,
			5,5,p1fdb[i],p1fdbbg[i])
			--p2 line
			gui.drawRectangle(
			25+i*7,
			40+7,
			5,5,p2fdb[i],p2fdbbg[i])
			--always draw both lines or past ones disappear on the next frame
		end
	end
end
