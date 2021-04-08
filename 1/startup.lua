local dir = fs.exists("FindAPI.lua")

if fs.exists("FindAPI.lua") then
    os.loadAPI("FindAPI.lua")
else
    textutils.slowPrint("FindAPI.lua is missing from <<<ROOT>>>")
end

local CheckForItem = ((FindAPI ~= nil and FindAPI.CheckForItem) or (function(ItemType, ItemSlot)
    local hasItem = (peripheral.isPresent(ItemSlot) and peripheral.getType(ItemSlot) == ItemType)

    return hasItem, (hasItem and peripheral.wrap(ItemSlot) or nil)
end))

local hasModem = false

local Opened = false
local restarting = false

local debugEnabled1 = true
local debugEnabled2 = false
local debugEnabled3 = true

if pocket then
    textutils.slowPrint('Running on a Pocket Computer')
else
    textutils.slowPrint('Running on a standard Computer')
end

function Restart()
    restarting = true
    Opened = false
    rednet.open("right")
    -- rednet.host("HKBank","BankingPort1")
    -- rednet.host("HKBank","BankingPort2")
    rednet.broadcast("Main Frame Reloaded!")

    print("Hello. Hold Ctrl + T to terminate (quit) this program.")

    textutils.slowWrite("Main Frame Reloaded!")
    print("")

    function CheckConnection()
        local realModem = CheckForItem("modem")
        hasModem = CheckForItem("modem", "right")

        if debugEnabled3 then
            if realModem and not hasModem then
                print(realModem and (not hasModem and "Please place the modem on the right of the computer." or "Error?") or "Error!")
            end
        end
        --hasModem = CheckForItem("modem", "right") -- Has to be to the right since it wont work

        if not hasModem then
            return false
        elseif hasModem and not rednet.isOpen("right") then
            rednet.open("right")
        end

        if rednet.isOpen("right") then
            return true
        end

        return false
    end

    function WaitForReceive()
        if restarting then return end
        Opened = CheckConnection()
        if debugEnabled2 then
            print(Opened and "Has connection..." or "Doesn't have connection...")
        end
        if Opened then
            id,message,protocol = rednet.receive(1) -- Wait 1 second so we can access lua and all that if needed
            if id and message then
                textutils.slowWrite("PC" ..id.. (protocol ~= nil and " " .. protocol or "") .." - ")
                textutils.slowPrint(message)

                if protocol ~= nil then
                    if protocol == "DNSLookup" then
                        local ServerID = {rednet.lookup(message)}

                        for i=1,#ServerID do
                            print("Found a server on channel "..ServerID[i].."!")
                        end

                        rednet.send(id, ServerID, protocol)
                    end
                end
            end
        else
            sleep(1) -- Force wait 1 second so we dont Spam it Lol
        end
        WaitForReceive()
    end

    restarting = false
    WaitForReceive()
end

function Loop()
    local realModem = CheckForItem("modem")
    hasModem = CheckForItem("modem", "right")

    if debugEnabled1 then
        print(realModem and (not hasModem and "Please place the modem on the right of the computer.") or (hasModem and "Has modem... Restarting!" or "Doesn't have modem... Sleeping for 1 second..."))
    end
    if hasModem and not Opened then
        Restart()
    end
    sleep(1)
    Loop()
end

Loop()