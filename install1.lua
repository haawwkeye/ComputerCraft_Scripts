print('Downloading install1.lua...')
 
local url ='https://raw.githubusercontent.com/haawwkeye/ComputerCraft_Scripts/main/install1.lua'
local h = _G.http.get(url)
if not h then
  error('Failed to download installer')
end
 
local contents = h.readAll()
if not contents then
  error('Failed to download installer')
end
 
local fn, msg = load(contents, 'Installer.lua', nil, _ENV)
if not fn then
  _G.printError(msg)
else
  local args = { ... }
  fn(args[1])
end
