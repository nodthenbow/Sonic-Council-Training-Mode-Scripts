--[[
screenshots every frame while a move is active
starts 1 frame before, ends 1 frame after
intended to be used with the hitbox script
probs want to have view > display messages turned off 
(or you'll be seeing a lot of the screenshot message in the screenshots)
also intended to be used with a ffmpeg based batch file to turn these into gifs
the batch file has this:

ffmpeg -framerate 20 -i Yuko-%%04d.png Yuko-XYZ.gif
ffmpeg -framerate 20 -i Kato-%$04d.png Kato-XYZ.gif
ffmpeg -framerate 20 -i Mika-%%04d.png Mika-XYZ.gif
ffmpeg -framerate 20 -i Ishida-%%04d.png Ishida-XYZ.gif
ffmpeg -framerate 20 -i Naoko-%%04d.png Naoko-XYZ.gif
ffmpeg -framerate 20 -i Ai-%%04d.png Ai-XYZ.gif
ffmpeg -framerate 20 -i Rika-%%04d.png Rika-XYZ.gif
ffmpeg -framerate 20 -i Shibata-%%04d.png Shibata-XYZ.gif
ffmpeg -framerate 20 -i Kumiko-%%04d.png Kumiko-XYZ.gif
ffmpeg -framerate 20 -i Aya-%%04d.png Aya-XYZ.gif
ffmpeg -framerate 20 -i TAi-%%04d.png TAi-XYZ.gif
ffmpeg -framerate 20 -i SNaoko-%%04d.png SNaoko-XYZ.gif

so make that into a .bat and run it in the folder of screenshots
it'll make a gif for each character (and fail to make one for the characters not found)

Word of warning: this script will overwrite any screenshots with the same name 
This means if you do 5LK, then jump, you'll get your first frames of 5LK screenshot replaced with that jump

--]]

console.clear()
console.log("screenshotty woah, change the base path and reload the script if you haven't already") 


local prevAct = 2
local currAct = 2
local prevActOpp = 2
local currActOpp = 2
local ppA = 2
local ppAO = 2
local pa3 = 2
local pa3o = 2

local fnIndex = 0
local fnIndex2 = 0
local pathBase = "C:\\Users\\owner\\Pictures\\Video Projects\\screenies\\"

local characterName = { --index is the same as in game, which is found at p1Base / p2Base
    [0] = "Yuko", --Yuko
    [1] = "Kato", --Kato
    [2] = "Mika", --Mika 
	[3] = "Ishida", --Ishida
	[4] = "Naoko", --Naoko
	[5] = "Ai", --Ai
	[6] = "Rika", --Rika
	[7] = "Shibata", --Shibata
	[8] = "Kumiko", --Kumiko
	[9] = "Aya", --Aya
	[10] = "TAi", --Traitorous Ai
	[11] = "SNaoko" --Shadow Naoko
}
--client.setscreenshotosd(true)
while true do
	emu.frameadvance();
	if memory.read_u8(0xdbef8) == 4 then --makes sure that we are in an active match
		if prevAct == 2 then --first loop want to not take a screenshot
			prevAct = 1
			currAct = prevAct
			prevActOpp = prevAct
			currActOpp = prevAct
			ppA = 1
			ppAO = 1
			pa3 = 1
			pa3o = 1
		end
		
		currAct = memory.read_u8(0xdba5d)
		currActOpp = memory.read_u8(0xdbb99)
		--console.log(currAct, prevAct, currActOpp, prevActOpp, notInNeutral, notInNeutralPrev)

		if currAct == 0 or prevAct == 0 or ppA == 0 or pa3 == 0 then
			pathFull = pathBase .. characterName[memory.read_u8(0x0DBA00)] .. "-"
			if fnIndex < 1000 then pathFull = pathFull .. "0" end
			if fnIndex < 100 then pathFull = pathFull .. "0" end
			if fnIndex < 10 then pathFull = pathFull .. "0" end
			pathFull = pathFull .. fnIndex .. ".png"
			fnIndex = fnIndex + 1
			client.screenshot(pathFull)
			console.log("Screenshot created: " .. pathFull)
		end
		
		if currActOpp == 0 or prevActOpp == 0 or ppAO == 0 or pa3o == 0 then
			pathFull = pathBase .. characterName[memory.read_u8(0x0DBA00+0x13c)] .. "-"
			if fnIndex2 < 1000 then pathFull = pathFull .. "0" end
			if fnIndex2 < 100 then pathFull = pathFull .. "0" end
			if fnIndex2 < 10 then pathFull = pathFull .. "0" end
			pathFull = pathFull .. fnIndex2 .. ".png"
			fnIndex2 = fnIndex2 + 1
			client.screenshot(pathFull)
			console.log("Screenshot created: " .. pathFull)
		end
		
		if false == (currAct == 0 or prevAct == 0 or ppA == 0 or pa3 == 0) then
			fnIndex = 0
		end
		
		if false == (currActOpp == 0 or prevActOpp == 0 or ppAO == 0 or pa3o == 0) then
			fnIndex2 = 0
		end
		
		pa3 = ppA
		pa3o = ppAO
		ppA = prevAct
		ppAO = prevActOpp
		prevAct = currAct
		prevActOpp = currActOpp

	end
end