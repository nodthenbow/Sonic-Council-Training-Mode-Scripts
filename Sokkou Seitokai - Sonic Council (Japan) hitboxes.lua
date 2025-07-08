--This is a hitbox viewer for Sokkou Seitokai - Sonic Council for Bizhawk 2.10
--[[
Folder name: "Sokkou Seitokai - Sonic Council (Japan)"
SHA256 checksum for data and names: e2394185d08792923044f912a263e71e7ca5d3a8f7bad234214a98ae74dd6490-00000009
]]
--If it works on future versions, cool. If not, I'm probably not going to update it.
--doesn't work on some stuff (like fireballs, pushboxes) because I didn't want to do more REing

--[[
known issues:
	throw height is wrong (it's infinite in game, I just made it a height of 20)
	invulnerability can be bypassed by some stuff (seems like a glitch in the game?)
potential issues:
	collision box is weird
	throws may be a pixel longer than they actually are
--]]
--the once loaded stuff
local p1Base = 0x0DBA00
local p2Base = 0x0DBB3C
local playerOffset = 0x13c

local characterBaseAddress = { --index is the same as in game, which is found at p1Base / p2Base
    [0] = 0x06B43C, --Yuko
    [1] = 0x06CAF4, --Kato
    [2] = 0x06E68C, --Mika 
	[3] = 0x0704A0, --Ishida
	[4] = 0x071F34, --Naoko
	[5] = 0x073BD8, --Ai
	[6] = 0x075798, --Rika
	[7] = 0x0772B0, --Shibata
	[8] = 0x078CD0, --Kumiko
	[9] = 0x07A630, --Aya
	[10] = 0x073BD8, --Traitorous Ai
	[11] = 0x071F34 --Shadow Naoko
}

--colours
local lightGreen = 0xb000c000 --hurtbox
local lightGreenBG = 0x7000c000
local lightRed = 0xb0ff0000 --hitbox
local lightRedBG = 0x70ff0000
local white = 0xb0ffffff --currently invuln hurtbox (if I implement that)
local whiteBG = 0x70ffffff
local yellow = 0xb0ffff00
local yellowBG = 0x70ffff00
local purple = 0xb0ff00ff
local purpleBG = 0x70ff00ff
local blue = 0xb00000ff
local blueBG = 0x700000ff


--screen position for character point offsets (I'm just guessing what they should be off visuals
local pointOffsetH = 165
local pointOffsetV = 119
--if it is wrong it's only a pixel off (v might be 2 off, it's harder to see)

--the once per frame stuff
--memory default is work ram high (starts at 0x06000000)
function fn()
    --p1 stuff
	local hurtboxBase = characterBaseAddress[memory.read_u8(p1Base)] 
	local activeHurtboxBase = hurtboxBase + memory.read_u16_be(p1Base+0xC)*4 --pNBase*4 is the offset for the address
	activeHurtboxBase = memory.read_u32_be(activeHurtboxBase)
	activeHurtboxBase = activeHurtboxBase - 0x06000000 --the saturn uses 06000000 to point to high ram, bizhawk doesn't
	local noBoxes = 0
	if activeHurtboxBase < 0 then 
		activeHurtboxBase = 0 
		noBoxes = 1
	end
	local hPos = memory.read_s32_be(p1Base+0x108) --h pos offset
	hPos = hPos / 65536
	local vPos = memory.read_s32_be(p1Base+0x10c) --v pos offset
	vPos = vPos / 65536
	local numHurtboxes = memory.read_u8(activeHurtboxBase)
	local screenEdgeH = memory.read_s32_be(0x0DBdf0) --there are 2 screen pos variables, only diff is one is offset. 0x0db6a4 is 65536 to 20905984, 0x0dbdf0 is -10420224 to 10420224
	screenEdgeH = screenEdgeH / 65536 --fixing resolution to match hurtbox location
	local screenEdgeV = memory.read_s32_be(0x0dbcc4)
	screenEdgeV = screenEdgeV / 65536
	local charPointHPos = hPos-screenEdgeH+pointOffsetH
	local charPointVPos = vPos-screenEdgeV+pointOffsetV
	gui.drawRectangle(charPointHPos,charPointVPos,1,1,"white","white")
	local charWidth = 0
	local charHeight = 0
	local color = ""
	local colorBG = ""
	local hori1 = 0
	local hori2 = 0
	local vert1 = 0
	local vert2 = 0
	local facing = 1
	local temp = 0
	for i = 0, numHurtboxes-1, 1 do
		if noBoxes == 1 then break end
		hori1 = memory.read_u8(activeHurtboxBase+1+4*i)
		hori2 = memory.read_u8(activeHurtboxBase+3+4*i)
		vert1 = memory.read_u8(activeHurtboxBase+2+4*i)
		vert2 = memory.read_u8(activeHurtboxBase+4+4*i)
		facing = 1
		if memory.read_u8(0xdba4a) == 1 then
			hori1 = hori1 * -1
			hori2 = hori2 * -1
			facing = -1
		end
		
		if hori1 > hori2 then
			temp = hori2
			hori2 = hori1
			hori1 = temp
		end
		if vert1 > vert2 then
			temp = vert2
			vert2 = vert1
			vert1 = temp
		end
		
		charWidth = memory.read_s16_be(p1Base+0x2e) * facing
		charHeight = memory.read_s16_be(p1Base+0x30)
		colour = lightGreen
		colourBG = lightGreenBG
		if memory.read_s8(p1Base+0x59) == 1 then
			colour = white
			colourBG = whiteBG
		end
		gui.drawRectangle(charPointHPos+hori1+charWidth, charPointVPos+vert1+charHeight, math.abs(hori1-hori2), math.abs(vert1-vert2), colour,colourBG)
	end
	
	--hitboxes for p1
	local numHitboxes = memory.read_s8(p1Base+0x67)
	local activeHitboxBase = 0x0dbc80 --idk how to calculate this from pNBase, so hard coding it 
	for i = 0, numHitboxes-1, 1 do
		if memory.read_u8(0x0DBA66) == 0 then break end
		hori1 = memory.read_s16_be(activeHitboxBase+0+i*8)
		hori2 = memory.read_s16_be(activeHitboxBase+4+i*8)
		vert1 = memory.read_s16_be(activeHitboxBase+2+i*8)
		vert2 = memory.read_s16_be(activeHitboxBase+6+i*8)

		if hori1 > hori2 then
			temp = hori2
			hori2 = hori1
			hori1 = temp
		end
		if vert1 > vert2 then
			temp = vert2
			vert2 = vert1
			vert1 = temp
		end
		
		colour = lightRed
		colourBG = lightRedBG
		
		gui.drawRectangle(charPointHPos+hori1+0, charPointVPos+vert1, math.abs(hori1-hori2), math.abs(vert1-vert2), colour,colourBG)

	end
	
	--collision boxes and throws
	--dbb00 sw hori1 sw ver1?
	hori1 = memory.read_s16_be(0xdbb00)
	vert1 = memory.read_s16_be(0xdbb02)
	hori2 = memory.read_s16_be(0xdbb04)
	vert2 = memory.read_s16_be(0xdbb06)
	
	if hori1 > hori2 then
		temp = hori2
		hori2 = hori1
		hori1 = temp
	end
	if vert1 > vert2 then
		temp = vert2
		vert2 = vert1
		vert1 = temp
	end
	if memory.read_u8(0xdba4a) == 1 then
		temp = hori1-hori2
		hori1 = (hori1 * -1) + temp
		hori2 = (hori2 * -1) + temp
	end
	colour = yellow
	colourBG = yellowBG
	
	gui.drawRectangle(charPointHPos+hori1, charPointVPos+vert1, math.abs(hori1-hori2), math.abs(vert1-vert2), colour,colourBG)
	
	--throw stuff (uses collision boxes stuff)
	if memory.read_s8(0x0dba83) ~= 0 then 
		local throwRange = memory.read_s16_be(0x0dba86)
		local x1 = charPointHPos+hori1+math.abs(hori1-hori2) + 1
		if memory.read_u8(0xdba4a) == 1 then
			x1 = charPointHPos+hori1+(throwRange*-1) -1
		end
		gui.drawRectangle(x1,charPointVPos-20,throwRange,20,blue,blueBG)
	end
	
	--fireballs (for both)
	local fbDraw = 0
	local fbNotActive = 0
	local fbArrayBase = 0x0dbcf0
	for i = 0, 16, 1 do
		fbDraw = memory.read_u8(fbArrayBase + (i*0x10))
		fbDraw = fbDraw / 64
		fbNotActive = memory.read_u8(fbArrayBase + 2+(i*0x10))
		if fbDraw > 1 and fbNotActive ~= 1 then
			hori1 = memory.read_s16_be(fbArrayBase +8 +(i*0x10))
			vert1 = memory.read_s16_be(fbArrayBase +10 +(i*0x10))
			hori2 = memory.read_s16_be(fbArrayBase +12 +(i*0x10))
			vert2 = memory.read_s16_be(fbArrayBase +14 +(i*0x10))
			hPos = memory.read_s16_be(fbArrayBase +4 +(i*0x10))
			vPos = memory.read_s16_be(fbArrayBase +6 +(i*0x10))
			
			if hori1 > hori2 then
				temp = hori2
				hori2 = hori1
				hori1 = temp
			end
			if vert1 > vert2 then
				temp = vert2
				vert2 = vert1
				vert1 = temp
			end
			
			colour = purple
			colourBG = purpleBG
			
			gui.drawRectangle(hPos+hori1-screenEdgeH+pointOffsetH, vPos+vert1-screenEdgeV+pointOffsetV, math.abs(hori1-hori2), math.abs(vert1-vert2), colour,colourBG)
		end
	end
	
	
	--p2 stuff 
	hurtboxBase = characterBaseAddress[memory.read_u8(p2Base)] 
	activeHurtboxBase = hurtboxBase + memory.read_u16_be(p2Base+0xC)*4 --pNBase*4 is the offset for the address
	activeHurtboxBase = memory.read_u32_be(activeHurtboxBase)
	activeHurtboxBase = activeHurtboxBase - 0x06000000 --the saturn uses 06000000 to point to high ram, bizhawk doesn't
	noBoxes = 0
	if activeHurtboxBase < 0 then 
		activeHurtboxBase = 0 
		noBoxes = 1
	end
	hPos = memory.read_s32_be(p2Base+0x108) --h pos offset
	hPos = hPos / 65536
	vPos = memory.read_s32_be(p2Base+0x10c) --v pos offset
	vPos = vPos / 65536
	numHurtboxes = memory.read_u8(activeHurtboxBase)
	charPointHPos = hPos-screenEdgeH+pointOffsetH 
	charPointVPos = vPos-screenEdgeV+pointOffsetV
	gui.drawRectangle(charPointHPos,charPointVPos,1,1,"white","white")

	--hurtboxes
	for i = 0, numHurtboxes-1, 1 do
		if noBoxes == 1 then break end
		hori1 = memory.read_u8(activeHurtboxBase+1+4*i)
		hori2 = memory.read_u8(activeHurtboxBase+3+4*i)
		vert1 = memory.read_u8(activeHurtboxBase+2+4*i)
		vert2 = memory.read_u8(activeHurtboxBase+4+4*i)
		facing = 1
		if memory.read_u8(0xdba4a+0x13c) == 1 then
			hori1 = hori1 * -1
			hori2 = hori2 * -1
			facing = -1
		end
		
		if hori1 > hori2 then
			temp = hori2
			hori2 = hori1
			hori1 = temp
		end
		if vert1 > vert2 then
			temp = vert2
			vert2 = vert1
			vert1 = temp
		end
		
		charWidth = memory.read_s16_be(p2Base+0x2e) * facing
		charHeight = memory.read_s16_be(p2Base+0x30)
		colour = lightGreen
		colourBG = lightGreenBG
		if memory.read_s8(p1Base+0x59+0x13c) == 1 then
			colour = white
			colourBG = whiteBG
		end
		gui.drawRectangle(charPointHPos+hori1+charWidth, charPointVPos+vert1+charHeight, math.abs(hori1-hori2), math.abs(vert1-vert2), colour,colourBG)
	end
	
	
	--hitboxes
	numHitboxes = memory.read_s8(p2Base+0x67)
	activeHitboxBase = 0x0dbca0
	charWidth = 0
	for i = 0, numHitboxes-1, 1 do
		if memory.read_u8(0x0DBA66+0x13c) == 0 then break end
		hori1 = memory.read_s16_be(activeHitboxBase+0+i*8)
		hori2 = memory.read_s16_be(activeHitboxBase+4+i*8)
		vert1 = memory.read_s16_be(activeHitboxBase+2+i*8)
		vert2 = memory.read_s16_be(activeHitboxBase+6+i*8)

		if hori1 > hori2 then
			temp = hori2
			hori2 = hori1
			hori1 = temp
		end
		if vert1 > vert2 then
			temp = vert2
			vert2 = vert1
			vert1 = temp
		end
		
		colour = lightRed
		colourBG = lightRedBG
		
		gui.drawRectangle(charPointHPos+hori1+0, charPointVPos+vert1, math.abs(hori1-hori2), math.abs(vert1-vert2), colour,colourBG)

	end
	
	
	--collision boxes and throws
	--dbb00 sw hori1 sw ver1?
	hori1 = memory.read_s16_be(0xdbb00+0x13c)
	vert1 = memory.read_s16_be(0xdbb02+0x13c)
	hori2 = memory.read_s16_be(0xdbb04+0x13c)
	vert2 = memory.read_s16_be(0xdbb06+0x13c)
	
	if hori1 > hori2 then
		temp = hori2
		hori2 = hori1
		hori1 = temp
	end
	if vert1 > vert2 then
		temp = vert2
		vert2 = vert1
		vert1 = temp
	end
	if memory.read_u8(0xdba4a+0x13c) == 1 then
		temp = hori1-hori2
		hori1 = (hori1 * -1) + temp
		hori2 = (hori2 * -1) + temp
	end
	colour = yellow
	colourBG = yellowBG
	
	gui.drawRectangle(charPointHPos+hori1, charPointVPos+vert1, math.abs(hori1-hori2), math.abs(vert1-vert2), colour,colourBG)
	
	--throw stuff (uses collision boxes stuff)
	if memory.read_s8(0x0dba83+0x13c) ~= 0 then 
		local throwRange = memory.read_s16_be(0x0dba86+0x13c)
		local x1 = charPointHPos+hori1+math.abs(hori1-hori2) + 1
		if memory.read_u8(0xdba4a+0x13c) == 1 then
			x1 = charPointHPos+hori1+(throwRange*-1) -1
		end
		gui.drawRectangle(x1,charPointVPos-20,throwRange,20,blue,blueBG)
	end
	
end
console.clear()
event.unregisterbyname("Sonic Council Hitbox Viewer") --don't want to double run this
event.onframestart(fn, "Sonic Council Hitbox Viewer")
