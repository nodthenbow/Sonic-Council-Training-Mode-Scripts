--[[
Damage, stun, and meter change history.
Grabs the changes in all those parts, ignoring the -1 ticks of stun
--]]


local debugInfo = 0


local p1HealthStart = 0
local p2HealthStart = 0
local p1StunStart = 0
local p2StunStart = 0
local p1MeterBigStart = 0
local p2MeterBigStart = 0
local p1MeterSmallStart = 0
local p2MeterSmallStart = 0

local p1DamLast = 0
local p2DamLast = 0
local p1StunLast = 0
local p2StunLast = 0
local p1MeterGainLast = 0
local p2MeterGainLast = 0

local dmgP1Index = 0
local stunP1Index = 0
local meterP1Index = 0
local dmgP2Index = 0
local stunP2Index = 0
local meterP2Index = 0
local dmgP1Hist = {}
local stunP1Hist = {}
local meterP1Hist = {}
local dmgP2Hist = {}
local stunP2Hist = {}
local meterP2Hist = {}

local histSize = 12

for i=0, histSize do
	dmgP1Hist[i] = 0
	stunP1Hist[i] = 0
	meterP1Hist[i] = 0
	dmgP2Hist[i] = 0
	stunP2Hist[i] = 0
	meterP2Hist[i] = 0
end

local firstloop = 1

while true do
	emu.frameadvance();
	if memory.read_u8(0xdbef8) == 4 then --makes sure that we are in an active match
		if firstloop == 1 then 
			firstloop = 0
			p1HealthStart = memory.read_s16_be(0xdba92)
			p2HealthStart = memory.read_s16_be(0xdba92+0x13c)
			p1StunStart = memory.read_s16_be(0xdba96)
			p2StunStart = memory.read_s16_be(0xdba96+0x13c)
			p1MeterBigStart = memory.read_u8(0xdba9e)
			p2MeterBigStart = memory.read_u8(0xdba9e+0x13c)
			p1MeterSmallStart = memory.read_u16_be(0xdba9c)
			p2MeterSmallStart = memory.read_u16_be(0xdba9c+0x13c)
		end
		temp = memory.read_s16_be(0xdba92) --p1 health
		p1DamLast = p1HealthStart - temp
		temp = memory.read_s16_be(0xdba92+0x13c) --p2 health
		p2DamLast = p2HealthStart - temp
		temp = memory.read_s16_be(0xdba96) --p1 stun
		p1StunLast = temp - p1StunStart
		temp = memory.read_s16_be(0xdba96+0x13c) --p2 stun
		p2StunLast = temp - p2StunStart
		temp = memory.read_u8(0xdba9e)*800 + memory.read_u16_be(0xdba9c) --p1 meter big and small
		p1MeterGainLast = temp - (p1MeterBigStart*800+p1MeterSmallStart)
		temp = memory.read_u8(0xdba9e+0x13c)*800 + memory.read_u16_be(0xdba9c+0x13c) --p2 meter
		p2MeterGainLast = temp - (p2MeterBigStart*800+p2MeterSmallStart)
		
		if p1DamLast ~= 0 then
			p1HealthStart = memory.read_s16_be(0xdba92)
			dmgP1Index = dmgP1Index + 1
			if dmgP1Index > histSize then dmgP1Index = 0 end
			dmgP1Hist[dmgP1Index] = p1DamLast
		end 
		if p2DamLast ~= 0 then 
			p2HealthStart = memory.read_s16_be(0xdba92+0x13c)
			dmgP2Index = dmgP2Index + 1
			if dmgP2Index > histSize then dmgP2Index = 0 end
			dmgP2Hist[dmgP2Index] = p2DamLast
		end
		if p1StunLast ~= 0 then 
			p1StunStart = memory.read_s16_be(0xdba96)
			if p1StunLast > 0 then 
				stunP1Index = stunP1Index + 1 
				if stunP1Index > histSize then stunP1Index = 0 end
				stunP1Hist[stunP1Index] = p1StunLast
			end
		end
		if p2StunLast ~= 0 then 
			p2StunStart = memory.read_s16_be(0xdba96+0x13c)
			if p2StunLast > 0 then 
				stunP2Index = stunP2Index + 1 
				if stunP2Index > histSize then stunP2Index = 0 end
				stunP2Hist[stunP2Index] = p2StunLast
			end
		end
		if p1MeterGainLast ~= 0 then 
			p1MeterBigStart = memory.read_u8(0xdba9e) --800 points
			p1MeterSmallStart = memory.read_u16_be(0xdba9c)
			meterP1Index = meterP1Index + 1
			if meterP1Index > histSize then meterP1Index = 0 end
			meterP1Hist[meterP1Index] = p1MeterGainLast
		end
		if p2MeterGainLast ~= 0 then 
			p2MeterBigStart = memory.read_u8(0xdba9e+0x13c) --800 points
			p2MeterSmallStart = memory.read_u16_be(0xdba9c+0x13c)
			meterP2Index = meterP2Index + 1
			if meterP2Index > histSize then meterP2Index = 0 end
			meterP2Hist[meterP2Index] = p2MeterGainLast
		end
		
		offsetx = 21
		offsetx2 = 245
		offsety = 110
		offsetymult = 7
		for i=0, histSize do
			--gui.pixelText(x,y,text)
			--p1 stuff
			gui.pixelText(offsetx,offsety+i*offsetymult,dmgP2Hist[i]) --damage
			gui.pixelText(offsetx+20,offsety+i*offsetymult,stunP2Hist[i]) --damage
			gui.pixelText(offsetx+40,offsety+i*offsetymult,meterP1Hist[i]) --damage
			--p2 line
			gui.pixelText(offsetx2,offsety+i*offsetymult,dmgP1Hist[i]) --damage
			gui.pixelText(offsetx2+20,offsety+i*offsetymult,stunP1Hist[i]) --damage
			gui.pixelText(offsetx2+40,offsety+i*offsetymult,meterP2Hist[i]) --damage
			--always draw all text or past ones disappear on the next frame
		end
		--p1 legend/pointers
		gui.pixelText(offsetx,offsety-7, "dam  stun bar")
		gui.pixelText(offsetx+15,offsety+dmgP2Index*offsetymult, "<")
		gui.pixelText(offsetx+35,offsety+stunP2Index*offsetymult, "<")
		gui.pixelText(offsetx+55,offsety+meterP1Index*offsetymult, "<")
		--p2 legend/pointers
		gui.pixelText(offsetx2,offsety-7, "dam  stun bar")
		gui.pixelText(offsetx2+15,offsety+dmgP1Index*offsetymult, "<")
		gui.pixelText(offsetx2+35,offsety+stunP1Index*offsetymult, "<")
		gui.pixelText(offsetx2+55,offsety+meterP2Index*offsetymult, "<")
		
	end
end
