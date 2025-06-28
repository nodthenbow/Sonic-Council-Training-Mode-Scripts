--[[
Frame data script for p1
grabs damage, stun, meter gain, startup on contact, and frame advantage
i might make this grab all startup, active, and recovery as well at some point
might make this work for p2 as well at some point, probs not though
probs will investigate the other actionable flag that is +1 offset from the used flag
--]]
prevAct = 2
currAct = 2
prevActOpp = 2
currActOpp = 2

inMove = 0
inMoveOpp = 0
framesOfAct = 0
framesOfActOpp = 0

notInNeutral = 0
notInNeutralPrev = 0
healthRefill = 1

p1HealthStart = 0
p2HealthStart = 0
p1StunStart = 0
p2StunStart = 0
p1MeterBigStart = 0
p2MeterBigStart = 0
p1MeterSmallStart = 0
p2MeterSmallStart = 0
p1MeterBigPrev = 0
p2MeterBigPrev = 0
p1MeterSmallPrev = 0
p2MeterSmallPrev = 0

console.clear()
console.log("Warning about frame advantage: both players go through 1 frame of idle at the end of all grounded recovery (including dash startup), you can block and nothing else (wakeup does not force this, wakeup dp is real). A move that is +9 on hit will only link with a move that has a startup <= 8, but a frame advantage of 0 means if both players press the same speed of a button it will trade still.") 

while true do
	emu.frameadvance();
	if memory.read_u8(0xdbef8) == 4 then --makes sure that we are in an active match
		if prevAct == 2 then --first loop want to init with something that isn't garbage data
			prevAct = memory.read_u8(0xba5d)
			currAct = prevAct
			prevActOpp = prevAct
			currActOpp = prevAct
		end
		
		currAct = memory.read_u8(0xdba5d)
		currActOpp = memory.read_u8(0xdbb99)
		--console.log(currAct, prevAct, currActOpp, prevActOpp, notInNeutral, notInNeutralPrev)
		if prevAct == 1 and currAct == 1 and prevActOpp == 1 and currActOpp == 1 and notInNeutral == 1 then
			ret = "p1 advantage = " .. framesOfAct-1 - (framesOfActOpp-1) .. " move total = " .. inMove .. "\n"
			
			temp = memory.read_s16_be(0xdba92)
			if p1HealthStart ~= temp then ret = ret .. "p1 dam = " .. p1HealthStart - temp .. " \n" end
			temp = memory.read_s16_be(0xdba92+0x13c)
			if p2HealthStart ~= temp then ret = ret .. "p2 dam = " .. p2HealthStart - temp .. " \n" end
			
			temp = memory.read_s16_be(0xdba96)
			if p1StunStart ~= temp then ret = ret .. "p1 stun = " .. p1StunStart - temp .. " \n" end
			
			temp = memory.read_s16_be(0xdba96+0x13c)
			if p2StunStart ~= temp then ret = ret .. "p2 stun = " .. p2StunStart - temp .. " \n" end

			temp = memory.read_u8(0xdba9e)*800 + memory.read_u16_be(0xdba9c)
			if (p1MeterBigStart * 800 + p1MeterSmallStart) ~= temp then 
				ret = ret .. "p1 meter gain = " .. temp - (p1MeterBigStart*800+p1MeterSmallStart) .. "\n"
			end
			temp = memory.read_u8(0xdba9e+0x13c)*800 + memory.read_u16_be(0xdba9c+0x13c)
			if p2MeterBigStart*800+p2MeterSmallStart ~= temp then 
				ret = ret .. "p2 meter gain = " .. temp - (p2MeterBigStart*800+p2MeterSmallStart)
			end
			
			console.log(ret)
			console.log("")
			notInNeutral = 0
			notInNeutralPrev = 0
			framesOfAct = 0
			framesOfActOpp = 0
			inMove = 0
			inMoveOpp = 0
		end
		
		if currAct == 0 or currActOpp == 0 then notInNeutral = 1 end
		if prevAct == 1 and currAct == 0 then notInNeutral = 1 end
		if prevActOpp == 1 and currActOpp == 0 then notInNeutral = 1 end
		if notInNeutral == 1 and notInNeutralPrev ~= 1 then
			notInNeutralPrev = 1
			if healthRefill == 1 then
				if memory.read_s16_be(0xdba92) < 700 then memory.write_s16_be(0xdba92, 700) end
				if memory.read_s16_be(0xdbbce) < 700 then memory.write_s16_be(0xdba92+0x13c, 700) end
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
		if prevActOpp == 1 and currActOpp == 0 and currAct == 0 then 
			console.log("startup = " .. inMove+framesOfAct) 
			framesOfActOpp = 0
		end
		if notInNeutral == 1 then
			if currAct == 0 then inMove = inMove + 1 end
			if currAct == 1 then framesOfAct = framesOfAct + 1 end
			if currActOpp == 0 then inMoveOpp = inMoveOpp + 1 end
			if currActOpp == 1 then framesOfActOpp = framesOfActOpp + 1 end
			
		end
		
		p1MeterBigPrev = memory.read_u8(0xdba9e)
		p2MeterBigPrev = memory.read_u8(0xdba9e+0x13c)
		p1MeterSmallPrev = memory.read_u16_be(0xdba9c)
		p2MeterSmallPrev = memory.read_u16_be(0xdba9c+0x13c)
		prevAct = currAct
		prevActOpp = currActOpp
	end
end
