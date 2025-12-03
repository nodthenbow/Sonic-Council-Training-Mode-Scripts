--[[
Frame data script for both players
grabs damage, stun, meter gain, startup on contact, and frame advantage
i might make this count all startup, active, and recovery at some point
probs will investigate the other actionable flag that is +1 offset from the used flag
(pretty sure it's just for rolls and guard cancel or something, maybe the buffer too?)

you can mess with the startup number for the other player with fireballs and stuff, but it makes it easier to get startup for delayed fireballs like naoko's c214K moves
advantage on delayed fireballs is just the hitstun/blockstun of the fireball, you can figure out the real advantage by taking startup, minus the total on whiff, plus advantage on hit/block
naoko's c236k is still wrong, but that's very hard to fix because the fireball spawns way after the move "ends"
juggle advantage is funky if the opponent was invuln multiple times in one string of actions 
juggle is just opp advantage frames - invuln frames, it doesn't actually care about juggles
wouldn't work with ai throw because they are invuln twice, so there's a hacky fix for that in place
--]]

healthRefill = 1 --change to 0/1 to turn off/on auto health refill
writeToConsole = 0 -- change to 0/1 to turn off/on writing to console
writeToScreen = 1 -- change to 0/1 to turn off/on writing to screen

console.clear()
console.log("Warning about frame advantage: both players go through 1 frame of idle at the end of all recovery (including dash startup), you can block and nothing else (wakeup lets specials bypass this, wakeup dp is real, wakeup throw is not). A move that is +9 on hit will only link with a move that has a startup <= 8, but a frame advantage of 0 means if both players press the same speed of a button it will trade still.\n\nYou can turn off/on console by setting writeToConsole = 0 or 1, as with writeToScreen = 0 or 1, and healthRefill = 0 or 1, at any time using the console") 

local debugInfo = 0

local prevAct = 2
local currAct = 2
local prevActOpp = 2
local currActOpp = 2

local inMove = 0
local inMoveOpp = 0
local framesOfAct = 0
local framesOfActOpp = 0

local notInNeutral = 0
local notInNeutralPrev = 0

local p1HealthStart = 0
local p2HealthStart = 0
local p1StunStart = 0
local p2StunStart = 0
local p1MeterBigStart = 0
local p2MeterBigStart = 0
local p1MeterSmallStart = 0
local p2MeterSmallStart = 0
local p1MeterBigPrev = 0
local p2MeterBigPrev = 0
local p1MeterSmallPrev = 0
local p2MeterSmallPrev = 0

local screenFreeze = 0
local screenFreezeCount = 0
local startupPreFreeze = 0

local p1InvulnCount = 0
local p2InvulnCount = 0

local toWrite = 0
--local ret = ""
--local ret2 = ""

local textbox1 = "Startup = " .. 0 .. "\n" .. 
"Screen freeze = " .. 0 .. "\n" .. 
"Advantage = " .. 0 .. "\n" ..
"Total = " .. 0 .. "\n" ..
"P1 damage dealt = " .. 0 .. "\n" ..
"P1 stun dealt = " .. 0 .. "\n" ..
"P1 meter gained = " .. 0 .. "\n"

local textbox2 = "Startup = " .. 0 .. "\n" .. 
"Screen freeze = " .. 0 .. "\n" .. 
"Advantage = " .. 0 .. "\n" ..
"Total = " .. 0 .. "\n" ..
"P2 damage dealt = " .. 0 .. "\n" ..
"P2 stun dealth = " .. 0 .. "\n" ..
"P2 meter gained = " .. 0 .. "\n"

local startupLast = 0
local startupLastOpp = 0
local screenFreezeLast = 0
local p1DamLast = 0
local p2DamLast = 0
local p1StunLast = 0
local p2StunLast = 0
local p1MeterGainLast = 0
local p2MeterGainLast = 0
local advLast = 0
local advLastOpp = 0
local moveTotalLast = 0
local moveTotalLastOpp = 0
local fbDraw = 0
local fbNotActive = 0
local fbArrayBase = 0x0dbcf0
local fbActive = 0

while true do
	emu.frameadvance();
	if memory.read_u8(0xdbef8) == 4 then --makes sure that we are in an active match
		if prevAct == 2 then --first loop want to init with something that isn't garbage data
			prevAct = memory.read_u8(0xba5d)
			currAct = prevAct
			prevActOpp = prevAct
			currActOpp = prevAct
		end
		
		
		currAct = memory.read_u8(0xdba5d) --flag that is true if the character is actionable
		currActOpp = memory.read_u8(0xdbb99) --same flag but for p2 (the offset is 0x13c, same as most stuff)
		--console.log(currAct, prevAct, currActOpp, prevActOpp, notInNeutral, notInNeutralPrev)
		if prevAct == 1 and currAct == 1 and prevActOpp == 1 and currActOpp == 1 and notInNeutral == 1 and fbActive ~= 1 then
			--this means something happened and it should populate the frame data output
			advLast = framesOfAct - framesOfActOpp 
			advLastOpp = advLast*(-1) --p2 advantage is the negative of p1 advantage
			
			if p1InvulnCount > 0 then --calculates juggle advantage for p2
				if advLastOpp-p1InvulnCount > 0 then --don't show negative juggle advantages
					advLastOpp = "" .. advLastOpp .. " (" .. advLastOpp-p1InvulnCount-1 .. "j)" 
				end
			end
			if p2InvulnCount > 0 then --same as above but for p1 
				if advLast-p2InvulnCount > 0 then
					advLast = "" .. advLast .. " (" .. advLast-p2InvulnCount-1 .. "j)" 
				end
			end
			
			moveTotalLast = inMove
			moveTotalLastOpp = inMoveOpp
			
			temp = memory.read_s16_be(0xdba92) --p1 health
			--if p1HealthStart ~= temp then ret = ret .. "p1 dam = " .. p1HealthStart - temp .. " \n" end
			p1DamLast = p1HealthStart - temp
			temp = memory.read_s16_be(0xdba92+0x13c) --p2 health
			--if p2HealthStart ~= temp then ret = ret .. "p2 dam = " .. p2HealthStart - temp .. " \n" end
			p2DamLast = p2HealthStart - temp
			temp = memory.read_s16_be(0xdba96) --p1 stun
			--if p1StunStart ~= temp then ret = ret .. "p1 stun = " .. temp - p1StunStart .. " \n" end
			p1StunLast = temp - p1StunStart
			temp = memory.read_s16_be(0xdba96+0x13c) --p2 stun
			--if p2StunStart ~= temp then ret = ret .. "p2 stun = " .. temp - p2StunStart .. " \n" end
			p2StunLast = temp - p2StunStart
			temp = memory.read_u8(0xdba9e)*800 + memory.read_u16_be(0xdba9c) --p1 meter big and small
			--[[if (p1MeterBigStart * 800 + p1MeterSmallStart) ~= temp then 
				ret = ret .. "p1 meter gain = " .. temp - (p1MeterBigStart*800+p1MeterSmallStart) .. "\n"
			end--]]
			p1MeterGainLast = temp - (p1MeterBigStart*800+p1MeterSmallStart)
			temp = memory.read_u8(0xdba9e+0x13c)*800 + memory.read_u16_be(0xdba9c+0x13c) --p2 meter
			--[[if p2MeterBigStart*800+p2MeterSmallStart ~= temp then 
				ret = ret .. "p2 meter gain = " .. temp - (p2MeterBigStart*800+p2MeterSmallStart)
			end--]]
			p2MeterGainLast = temp - (p2MeterBigStart*800+p2MeterSmallStart)
			--gui.pixelText(100,100,ret)
			
			--console.log(ret)
			--console.log("")
			notInNeutral = 0
			notInNeutralPrev = 0
			framesOfAct = 0
			framesOfActOpp = 0
			inMove = 0
			inMoveOpp = 0
			screenFreezeCount = 0
			p1InvulnCount = 0
			p2InvulnCount = 0
			toWrite = 1
		end
		
		if currAct == 0 or currActOpp == 0 then notInNeutral = 1 end
		if prevAct == 1 and currAct == 0 then notInNeutral = 1 end
		if prevActOpp == 1 and currActOpp == 0 then notInNeutral = 1 end
		--if fireballs are active
		fbActive = 0
		for i = 0, 15, 1 do
			fbDraw = memory.read_u8(fbArrayBase + (i*0x10))
			fbDraw = fbDraw / 64 --matches the in game logic that determines if a fb is active
			fbNotActive = memory.read_u8(fbArrayBase + 2+(i*0x10))
			if debugInfo >= 2 then gui.pixelText(5+(math.ceil(math.floor(i/8))*65),100+((math.fmod(i,8)*20)),"\nfbActive = " .. fbActive .. "\nfbDraw = " .. fbDraw .. " " .. i) end
			if fbDraw >= 2 and fbNotActive ~= 1 then --game checks for floor(fbDraw)>1
				notInNeutral = 1
				fbActive = 1
				break
			end
		end
		
		if notInNeutral == 1 and notInNeutralPrev ~= 1 then
			notInNeutralPrev = 1
			if healthRefill == 1 then
				local maxH = memory.read_s16_be(0xdba94)
				if memory.read_s16_be(0xdba92) < maxH then memory.write_s16_be(0xdba92, maxH) end
				maxH = memory.read_s16_be(0xdba94+0x13c)
				if memory.read_s16_be(0xdbbce) < maxH then memory.write_s16_be(0xdba92+0x13c, maxH) end
				--1000 is the highest health char's health (700 is lowest, change it to that if issues occur)
			end
			p1HealthStart = memory.read_s16_be(0xdba92)
			p2HealthStart = memory.read_s16_be(0xdba92+0x13c)
			p1StunStart = memory.read_s16_be(0xdba96)
			p2StunStart = memory.read_s16_be(0xdba96+0x13c)
			p1MeterBigStart = p1MeterBigPrev
			p2MeterBigStart = p2MeterBigPrev
			p1MeterSmallStart = p1MeterSmallPrev
			p2MeterSmallStart = p2MeterSmallPrev
			--console.log("reset stats")
		end
		
		if prevActOpp == 1 and currActOpp == 0 --[[and currAct == 0]] then  --p2 startup calculator
			if screenFreezeCount > 0 then 
				--console.log("startup = " .. startupPreFreeze .. "+" .. inMove+framesOfAct-startupPreFreeze)
				--console.log("screen freeze lasted " .. screenFreezeCount .. " frames")
				startupLast = startupPreFreeze .. "+" .. inMove+framesOfAct-startupPreFreeze
			else
				--console.log("startup = " .. inMove+framesOfAct) 
				startupLast = inMove+framesOfAct
			end
			if currAct == 0 and fbActive == 0 then 
				screenFreezeLast = screenFreezeCount
				framesOfActOpp = 0
				startupPreFreeze = 0
				startupPreFreezeOpp = 0
			end
			framesOfAct = 0
			toWrite = 1
		end
		if prevAct == 1 and currAct == 0 --[[and currActOpp == 0]] then --p1 startup calculator
			if screenFreezeCount > 0 then 
				--console.log("startup = " .. startupPreFreeze .. "+" .. inMove+framesOfAct-startupPreFreeze)
				--console.log("screen freeze lasted " .. screenFreezeCount .. " frames")
				startupLastOpp = startupPreFreezeOpp .. "+" .. inMoveOpp+framesOfActOpp-startupPreFreezeOpp
			else
				--console.log("startup = " .. inMove+framesOfAct) 
				startupLastOpp = inMoveOpp+framesOfActOpp
			end
			if currActOpp == 0 and fbActive == 0 then
				screenFreezeLast = screenFreezeCount
				framesOfAct = 0
				startupPreFreeze = 0
				startupPreFreezeOpp = 0
			end
			framesOfActOpp = 0
			toWrite = 1
		end
		
		if notInNeutral == 1 then
			screenFreeze = memory.read_u8(0xdbdf6)
			if currAct == 0 and screenFreeze == 0 then inMove = inMove + 1 end
			if currAct == 1 and screenFreeze == 0 then framesOfAct = framesOfAct + 1 end
			if currActOpp == 0 and screenFreeze == 0 then inMoveOpp = inMoveOpp + 1 end
			if currActOpp == 1 and screenFreeze == 0 then framesOfActOpp = framesOfActOpp + 1 end
			if screenFreeze == 1 then 
				if screenFreezeCount == 0 then 
					startupPreFreeze = inMove+framesOfAct 
					startupPreFreezeOpp = inMoveOpp+framesOfActOpp
				end 
				screenFreezeCount = screenFreezeCount + 1 
			end
			if memory.read_s8(0x0DBA59) == 1 then p1InvulnCount = p1InvulnCount + 1 end
			if memory.read_s8(0x0DBA59+0x13c) == 1 then p2InvulnCount = p2InvulnCount + 1 end
			if memory.read_s8(0x0DBA59) == 1 and memory.read_s8(0x0DBA59+0x13c) == 1 then 
				p1InvulnCount = p1InvulnCount - 1
				p2InvulnCount = p2InvulnCount - 1
			end --very hacky fix to ai's throw not working
		end
		
		if debugInfo >= 1 then gui.pixelText(120,50,
			"notInNeutral = " .. notInNeutral .. 
			"\nnotInNeutralPrev = " .. notInNeutralPrev ..
			"\ncurrAct = " .. currAct ..
			"\ncurrActOpp = " .. currActOpp ..
			"\nprevAct = " .. prevAct ..
			"\nprevActOpp = " .. prevActOpp ..
			"\nframesOfAct = " .. framesOfAct ..
			"\nframesOfActOpp = ".. framesOfActOpp ..
			"\ninMove = " .. inMove ..
			"\ninMoveOpp = " .. inMoveOpp ..
			"\nscreenFreezeCount = " .. screenFreezeCount ..
			"\np1InvulnCount = " .. p1InvulnCount ..
			"\np2InvulnCount = " .. p2InvulnCount ..
			"\nstartupPreFreeze = " .. startupPreFreeze ..
			"\nstartupPreFreezeOpp = " .. startupPreFreezeOpp ..
			"\nfbActive = " .. fbActive .. 
			"\nfbDraw = " .. fbDraw .. 
			"\nfbNotActive = " .. fbNotActive ..
			"\ntoWrite = " .. toWrite)
		end
		
		p1MeterBigPrev = memory.read_u8(0xdba9e)
		p2MeterBigPrev = memory.read_u8(0xdba9e+0x13c)
		p1MeterSmallPrev = memory.read_u16_be(0xdba9c)
		p2MeterSmallPrev = memory.read_u16_be(0xdba9c+0x13c)
		prevAct = currAct
		prevActOpp = currActOpp
		
		if writeToConsole == 1 then 
			if toWrite == 1 then 
				textbox1 = "Startup = " .. startupLast .. "\n" .. 
				"Screen freeze = " .. screenFreezeLast .. "\n" .. 
				"Advantage = " .. advLast .. "\n" ..
				"Total = " .. moveTotalLast .. "\n" ..
				"P1 damage dealt = " .. p2DamLast .. "\n" ..
				"P1 stun dealt = " .. p2StunLast .. "\n" ..
				"P1 meter gained = " .. p1MeterGainLast .. "\n"
				
				textbox2 = "Startup = " .. startupLastOpp .. "\n" .. 
				"Screen freeze = " .. screenFreezeLast .. "\n" .. 
				"Advantage = " .. advLastOpp .. "\n" ..
				"Total = " .. moveTotalLastOpp .. "\n" ..
				"P2 damage dealt = " .. p1DamLast .. "\n" ..
				"P2 stun dealt = " .. p1StunLast .. "\n" ..
				"P2 meter gained = " .. p2MeterGainLast .. "\n"
				console.log(textbox1)
				console.log(textbox2)
			end
		end
		if writeToScreen == 1 then 
			gui.pixelText(81,10,"Health: " .. memory.read_s16_be(0xdba92) .. "/" .. memory.read_s16_be(0xdba94) .. "\n" .. "Stun: ".. memory.read_s16_be(0xdba96) .. "/" .. memory.read_s16_be(0xdba98) )
			gui.pixelText(183,10,"Health: " .. memory.read_s16_be(0xdba92+0x13c) .. "/" .. memory.read_s16_be(0xdba94+0x13c) .. "\n" .. "Stun: ".. memory.read_s16_be(0xdba96+0x13c) .. "/" .. memory.read_s16_be(0xdba98+0x13c) )
			gui.pixelText(25,225,memory.read_u16_be(0xdba9c)) --p1 meter small number
			gui.pixelText(289,225,memory.read_u16_be(0xdba9c+0x13c)) --p2 meter small number
			if toWrite == 1 then 
				textbox1 = "Startup = " .. startupLast .. "\n" .. 
				"Screen freeze = " .. screenFreezeLast .. "\n" .. 
				"Advantage = " .. advLast .. "\n" ..
				"Total = " .. moveTotalLast .. "\n" ..
				"P1 damage dealt = " .. p2DamLast .. "\n" ..
				"P1 stun dealt = " .. p2StunLast .. "\n" ..
				"P1 meter gained = " .. p1MeterGainLast .. "\n"
				
				textbox2 = "Startup = " .. startupLastOpp .. "\n" .. 
				"Screen freeze = " .. screenFreezeLast .. "\n" .. 
				"Advantage = " .. advLastOpp .. "\n" ..
				"Total = " .. moveTotalLastOpp .. "\n" ..
				"P2 damage dealt = " .. p1DamLast .. "\n" ..
				"P2 stun dealt = " .. p1StunLast .. "\n" ..
				"P2 meter gained = " .. p2MeterGainLast .. "\n"
			end
			gui.pixelText(21,55,textbox1)
			gui.pixelText(220,55,textbox2)
		end
		if toWrite == 1 then toWrite = 0 end
	end
end
