print('Downloading BackdoorClient.lua...')
 
local url ='https://raw.githubusercontent.com/haawwkeye/ComputerCraft_Scripts/Ame/BackdoorClient.lua'
local h = http.get(url)
if not h then
  error('Failed to download script')
end
 
local contents = h.readAll()
if not contents then
  error('Failed to get contents of script')
end
 
local file = fs.open("BackdoorClient.lua", "w");
file.write(contents);
file.close();
h.close();

shell.run("/BackdoorClient.lua"); -- Run it right after we install it
