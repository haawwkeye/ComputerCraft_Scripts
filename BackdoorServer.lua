--Server for backdoor commands
local port = 1489;
local modem = peripheral.find("modem") or error("A modem is required");

modem.open(port); -- This is so the server can request the id