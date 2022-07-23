print('Downloading MiningTurtle.lua...')
 
local url ='https://raw.githubusercontent.com/haawwkeye/ComputerCraft_Scripts/Ame/Turtle/MiningTurtle.lua'
local h = http.get(url)
if not h then
  error('Failed to download script')
end
 
local contents = h.readAll()
if not contents then
  error('Failed to get contents of script')
end

print('Downloaded! Adding content to /MiningTurtle.lua')

local file = fs.open("MiningTurtle.lua", "w");
file.write(contents);
file.close();
h.close();

print("Done!\nRunning MiningTurtle.lua...")
shell.run("/MiningTurtle.lua")
