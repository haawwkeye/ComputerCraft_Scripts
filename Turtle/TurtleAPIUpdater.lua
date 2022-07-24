
local updateApi = {}

updateApi._Version = "0.0.1";
updateApi.install = function() shell.run('wget https://raw.githubusercontent.com/haawwkeye/ComputerCraft_Scripts/Ame/Turtle/InstallTurtleAPI.lua InstallTurtleAPI.lua') end;

return updateApi;
