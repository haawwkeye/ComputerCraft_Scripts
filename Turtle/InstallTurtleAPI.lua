print('Downloading TurtleAPI.lua...')
 
local url ='https://raw.githubusercontent.com/haawwkeye/ComputerCraft_Scripts/Ame/Turtle/TurtleAPI.lua'
local h = http.get(url)
if not h then
  error('Failed to download script')
end
 
local contents = h.readAll()
if not contents then
  error('Failed to get contents of script')
end

print('Downloaded! Adding content to /TurtleAPI.lua')

local file = fs.open("TurtleAPI.lua", "w");
file.write(contents);
file.close();
h.close();

print("Done!\nRunning TurtleAPI.lua...")
shell.run("/TurtleAPI.lua")
