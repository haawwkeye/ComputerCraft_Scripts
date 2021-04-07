local hasModem = false

local Opened = false
local restarting = false

local debugEnabled1 = true
local debugEnabled2 = false

if pocket then
    textutils.slowPrint('Running on a Pocket Computer')
else
    textutils.slowPrint('Running on a standard Computer')
end

function Restart()
    restarting = true
    Opened = false
    rednet.open("right")
    rednet.broadcast("Main Frame Reloaded!")

    print("Hello. Hold Ctrl + T to terminate (quit) this program.")

    textutils.slowWrite("Main Frame Reloaded!")
    print("")

    function CheckConnection()
        hasModem = (peripheral.isPresent("right") and (peripheral.getType("right") == "modem"))

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
            id,message = rednet.receive(1) -- Wait 1 second so we can access lua and all that if needed
            if id and message then
                textutils.slowWrite("PC"..id.." - ")
                textutils.slowPrint(message)
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
    hasModem = (peripheral.isPresent("right") and (peripheral.getType("right") == "modem"))
    if debugEnabled1 then
        print(hasModem and "Has modem... Restarting!" or "Doesn't have modem... Sleeping for 1 second...")
    end
    if hasModem and not Opened then
        Restart()
    end
    sleep(1)
    Loop()
end

Loop()