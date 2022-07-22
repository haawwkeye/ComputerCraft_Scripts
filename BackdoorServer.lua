--Server for backdoor commands
local backdoorComps = {}
local mainport = 1489;
local modem = peripheral.find("modem") or error("A modem is required");

do -- Backdoor module
    local Backdoor = {}
    Backdoor.Comps = backdoorComps;
    function Backdoor:Send(CompId, script)
        local port = Backdoor.Comps[CompId];
        if port then
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
