--This is a hitbox viewer for Sokkou Seitokai - Sonic Council for Bizhawk 2.10
--[[
Folder name: "Sokkou Seitokai - Sonic Council (Japan)"
SHA256 checksum for data and names: e2394185d08792923044f912a263e71e7ca5d3a8f7bad234214a98ae74dd6490-00000009
]]
--If it works on future versions, cool. If not, I'm probably not going to update it.
--doesn't work on some stuff (like fireballs, pushboxes, throws) because I didn't want to do more REing

--[[
know issues:
	Boxes don't follow the screen vertically scrolling
	Kato's command grab doesn't show (it's probably an actual throw, unlike the other unblockables)
potential issues:
	screen offsets are probably wrong, can cause incorrect hit/hurtbox visual overlaps
	entirely untested with the unlockable goons, other than their base address being right
	supers (the were completely ignored while I was making this)
	juggle states might show invuln incorrectly
	unblockables are untested, they might be throws and not show up
--]]
--the once loaded stuff
p1Base = 0x0DBA00
p2Base = 0x0DBB3C
playerOffset = 0x13c

characterBaseAddress = { --index is the same as in game, which is found at p1Base / p2Base
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
lightGreen = 0xb000c000 --hurtbox
lightGreenBG = 0x7000c000
lightRed = 0xb0ff0000 --hitbox
lightRedBG = 0x70ff0000
white = 0xb0ffffff --currently invuln hurtbox (if I implement that)
whiteBG = 0x70ffffff

--screen position for character point offsets (I'm just guessing what they should be off visuals
pointOffsetH = 165
pointOffsetV = 55
--if it is wrong it's only a pixel off (v might be 2 off, it's harder to see)

--the once per frame stuff
--memory default is work ram high (starts at 0x06000000)
function fn()
    --p1 stuff
	hurtboxBase = characterBaseAddress[memory.read_u8(p1Base)] 
	activeHurtboxBase = hurtboxBase + memory.read_u16_be(p1Base+0xC)*4 --pNBase*4 is the offset for the address
	activeHurtboxBase = memory.read_u32_be(activeHurtboxBase)
	activeHurtboxBase = activeHurtboxBase - 0x06000000 --the saturn uses 06000000 to point to high ram, bizhawk doesn't
	noBoxes = 0
	if activeHurtboxBase < 0 then 
		activeHurtboxBase = 0 
		noBoxes = 1
	end
	hPos = memory.read_s32_be(p1Base+0x108) --h pos offset
	hPos = hPos / 65536
	vPos = memory.read_s32_be(p1Base+0x10c) --v pos offset
	vPos = vPos / 65536
	numHurtboxes = memory.read_u8(activeHurtboxBase)
	screenEdgeH = memory.read_s32_be(0x0DBdf0) --there are 2 screen pos variables, only diff is one is offset. 0x0db6a4 is 65536 to 20905984, 0x0dbdf0 is -10420224 to 10420224
	screenEdgeH = screenEdgeH / 65536 --fixing resolution to match hurtbox location
	screenEdgeV = memory.read_s32_be(0x0dbcc4)
	screenEdgeV = screenEdgeV / 65536
	charPointHPos = hPos-screenEdgeH+pointOffsetH
	charPointVPos = vPos+screenEdgeV+pointOffsetV
	gui.drawRectangle(charPointHPos,charPointVPos,1,1,"white","white")
	charWidth = 0
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
	numHitboxes = memory.read_s8(p1Base+0x67)
	activeHitboxBase = 0x0dbc80 --idk how to calculate this from pNBase, so hard coding it 
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
	charPointVPos = vPos+screenEdgeV+pointOffsetV
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
	
	
end
console.clear()
event.unregisterbyname("Sonic Council Hitbox Viewer") --don't want to double run this
event.onframestart(fn, "Sonic Council Hitbox Viewer")
