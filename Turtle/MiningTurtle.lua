-- Json Lib
do
    local json = { _version = "0.1.2" }

    -------------------------------------------------------------------------------
    -- Encode
    -------------------------------------------------------------------------------

    local encode

    local escape_char_map = {
    [ "\\" ] = "\\",
    [ "\"" ] = "\"",
    [ "\b" ] = "b",
    [ "\f" ] = "f",
    [ "\n" ] = "n",
    [ "\r" ] = "r",
    [ "\t" ] = "t",
    }

    local escape_char_map_inv = { [ "/" ] = "/" }
    for k, v in pairs(escape_char_map) do
    escape_char_map_inv[v] = k
    end


    local function escape_char(c)
    return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
    end


    local function encode_nil(val)
    return "null"
    end


    local function encode_table(val, stack)
    local res = {}
    stack = stack or {}

    -- Circular reference?
    if stack[val] then error("circular reference") end

    stack[val] = true

    if rawget(val, 1) ~= nil or next(val) == nil then
        -- Treat as array -- check keys are valid and it is not sparse
        local n = 0
        for k in pairs(val) do
        if type(k) ~= "number" then
            error("invalid table: mixed or invalid key types")
        end
        n = n + 1
        end
        if n ~= #val then
        error("invalid table: sparse array")
        end
        -- Encode
        for i, v in ipairs(val) do
        table.insert(res, encode(v, stack))
        end
        stack[val] = nil
        return "[" .. table.concat(res, ",") .. "]"

    else
        -- Treat as an object
        for k, v in pairs(val) do
        if type(k) ~= "string" then
            error("invalid table: mixed or invalid key types")
        end
        table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
        end
        stack[val] = nil
        return "{" .. table.concat(res, ",") .. "}"
    end
    end


    local function encode_string(val)
    return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
    end


    local function encode_number(val)
    -- Check for NaN, -inf and inf
    if val ~= val or val <= -math.huge or val >= math.huge then
        error("unexpected number value '" .. tostring(val) .. "'")
    end
    return string.format("%.14g", val)
    end


    local type_func_map = {
    [ "nil"     ] = encode_nil,
    [ "table"   ] = encode_table,
    [ "string"  ] = encode_string,
    [ "number"  ] = encode_number,
    [ "boolean" ] = tostring,
    }


    encode = function(val, stack)
    local t = type(val)
    local f = type_func_map[t]
    if f then
        return f(val, stack)
    end
    error("unexpected type '" .. t .. "'")
    end


    function json.encode(val)
    return ( encode(val) )
    end


    -------------------------------------------------------------------------------
    -- Decode
    -------------------------------------------------------------------------------

    local parse

    local function create_set(...)
    local res = {}
    for i = 1, select("#", ...) do
        res[ select(i, ...) ] = true
    end
    return res
    end

    local space_chars   = create_set(" ", "\t", "\r", "\n")
    local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
    local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
    local literals      = create_set("true", "false", "null")

    local literal_map = {
    [ "true"  ] = true,
    [ "false" ] = false,
    [ "null"  ] = nil,
    }


    local function next_char(str, idx, set, negate)
    for i = idx, #str do
        if set[str:sub(i, i)] ~= negate then
        return i
        end
    end
    return #str + 1
    end


    local function decode_error(str, idx, msg)
    local line_count = 1
    local col_count = 1
    for i = 1, idx - 1 do
        col_count = col_count + 1
        if str:sub(i, i) == "\n" then
        line_count = line_count + 1
        col_count = 1
        end
    end
    error( string.format("%s at line %d col %d", msg, line_count, col_count) )
    end


    local function codepoint_to_utf8(n)
    -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
    local f = math.floor
    if n <= 0x7f then
        return string.char(n)
    elseif n <= 0x7ff then
        return string.char(f(n / 64) + 192, n % 64 + 128)
    elseif n <= 0xffff then
        return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
    elseif n <= 0x10ffff then
        return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                        f(n % 4096 / 64) + 128, n % 64 + 128)
    end
    error( string.format("invalid unicode codepoint '%x'", n) )
    end


    local function parse_unicode_escape(s)
    local n1 = tonumber( s:sub(1, 4),  16 )
    local n2 = tonumber( s:sub(7, 10), 16 )
    -- Surrogate pair?
    if n2 then
        return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
    else
        return codepoint_to_utf8(n1)
    end
    end


    local function parse_string(str, i)
    local res = ""
    local j = i + 1
    local k = j

    while j <= #str do
        local x = str:byte(j)

        if x < 32 then
        decode_error(str, j, "control character in string")

        elseif x == 92 then -- `\`: Escape
        res = res .. str:sub(k, j - 1)
        j = j + 1
        local c = str:sub(j, j)
        if c == "u" then
            local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                    or str:match("^%x%x%x%x", j + 1)
                    or decode_error(str, j - 1, "invalid unicode escape in string")
            res = res .. parse_unicode_escape(hex)
            j = j + #hex
        else
            if not escape_chars[c] then
            decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
            end
            res = res .. escape_char_map_inv[c]
        end
        k = j + 1

        elseif x == 34 then -- `"`: End of string
        res = res .. str:sub(k, j - 1)
        return res, j + 1
        end

        j = j + 1
    end

    decode_error(str, i, "expected closing quote for string")
    end


    local function parse_number(str, i)
    local x = next_char(str, i, delim_chars)
    local s = str:sub(i, x - 1)
    local n = tonumber(s)
    if not n then
        decode_error(str, i, "invalid number '" .. s .. "'")
    end
    return n, x
    end


    local function parse_literal(str, i)
    local x = next_char(str, i, delim_chars)
    local word = str:sub(i, x - 1)
    if not literals[word] then
        decode_error(str, i, "invalid literal '" .. word .. "'")
    end
    return literal_map[word], x
    end


    local function parse_array(str, i)
    local res = {}
    local n = 1
    i = i + 1
    while 1 do
        local x
        i = next_char(str, i, space_chars, true)
        -- Empty / end of array?
        if str:sub(i, i) == "]" then
        i = i + 1
        break
        end
        -- Read token
        x, i = parse(str, i)
        res[n] = x
        n = n + 1
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "]" then break end
        if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
    end
    return res, i
    end


    local function parse_object(str, i)
    local res = {}
    i = i + 1
    while 1 do
        local key, val
        i = next_char(str, i, space_chars, true)
        -- Empty / end of object?
        if str:sub(i, i) == "}" then
        i = i + 1
        break
        end
        -- Read key
        if str:sub(i, i) ~= '"' then
        decode_error(str, i, "expected string for key")
        end
        key, i = parse(str, i)
        -- Read ':' delimiter
        i = next_char(str, i, space_chars, true)
        if str:sub(i, i) ~= ":" then
        decode_error(str, i, "expected ':' after key")
        end
        i = next_char(str, i + 1, space_chars, true)
        -- Read value
        val, i = parse(str, i)
        -- Set
        res[key] = val
        -- Next token
        i = next_char(str, i, space_chars, true)
        local chr = str:sub(i, i)
        i = i + 1
        if chr == "}" then break end
        if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
    end
    return res, i
    end


    local char_func_map = {
    [ '"' ] = parse_string,
    [ "0" ] = parse_number,
    [ "1" ] = parse_number,
    [ "2" ] = parse_number,
    [ "3" ] = parse_number,
    [ "4" ] = parse_number,
    [ "5" ] = parse_number,
    [ "6" ] = parse_number,
    [ "7" ] = parse_number,
    [ "8" ] = parse_number,
    [ "9" ] = parse_number,
    [ "-" ] = parse_number,
    [ "t" ] = parse_literal,
    [ "f" ] = parse_literal,
    [ "n" ] = parse_literal,
    [ "[" ] = parse_array,
    [ "{" ] = parse_object,
    }


    parse = function(str, idx)
    local chr = str:sub(idx, idx)
    local f = char_func_map[chr]
    if f then
        return f(str, idx)
    end
    decode_error(str, idx, "unexpected character '" .. chr .. "'")
    end


    function json.decode(str)
    if type(str) ~= "string" then
        error("expected argument of type string, got " .. type(str))
    end
    local res, idx = parse(str, next_char(str, 1, space_chars, true))
    idx = next_char(str, idx, space_chars, true)
    if idx <= #str then
        decode_error(str, idx, "trailing garbage")
    end
    return res
    end


    _ENV.json = json;
end

do
    -- Facing

    local this = {
        Enum = {
            Facing = {
                Unknown = -1;
                North = 1;
                East = 2;
                South = 3;
                West = 4;
            };
        };
        Internal = {};
        Settings = {
            CanMine = true;
            Position = vector.new(0,0,0);
            Facing = -1; -- N, E, S, W, ?
        };
    };
    
    function this.Internal:LoadFromFile()
        local file = fs.open(".turtleSettings.json", "r");
        if not file then
            this.Internal:SaveToFile();
            return;
        end
        if not file.readAll then file.readAll = function() return "" end end;
        local content = file.readAll();
        file.close()

        if content ~= "" then
            local settingsFile = json.decode(content);
            for i, v in pairs(settingsFile) do
                this.Settings[i] = v
            end
        else
            this.Internal:SaveToFile() -- New computer so we need to add the save file
        end
    end

    function this.Internal:SaveToFile()
        local file = fs.open(".turtleSettings.json", "w");
        local content = json.encode(this.Settings);
        if content ~= "" then
            file.write(content)
        end
        file.close()
    end

    -- Cords system

    function this:GetCords()
        return this.Settings.Position;
    end

    function this:SetCords(x, y, z)
        local pos = this.Settings.Position;

        if not x then x = pos.x end;
        if not y then y = pos.y end;
        if not z then z = pos.z end;

        this.Settings.Position = vector.new(x,y,z)
    end

    function this:Detect(Direction)
        if not Direction then return end;
        local dir = Direction:lower();
        local CanMine = this.Settings.CanMine;

        if not CanMine then return end;

        if dir == "forward" and turtle.detect() == true  then
            turtle.dig();
        elseif dir == "up" and turtle.detectUp() == true  then
            turtle.digUp();
        elseif dir == "down" and turtle.detectDown() == true then
            turtle.digDown();
        end
    end

    function this:Move(Direction)
        if not Direction then return end;
        this:Refuel()
        local dir = Direction:lower();
        local facing, newFacing = this.Settings.Facing, -1;
        if dir == "left" then
            newFacing = facing - 1;
        elseif dir == "right" then
            newFacing = facing + 1;
        elseif dir == "north" then
            newFacing = 1;
        elseif dir == "east" then
            newFacing = 2;
        elseif dir == "south" then
            newFacing = 3;
        elseif dir == "west" then
            newFacing = 4;
        end

        if newFacing == 0 then
            newFacing = 4;
        elseif newFacing == 5 then
            newFacing = 1;
        end

        if newFacing ~= -1 then
            this.Settings.Facing = newFacing;
        end

        this:Detect(dir)

        if dir == "left" then
            turtle.turnLeft()
        elseif dir == "right" then
            turtle.turnRight()
        elseif dir == "forward" then
            local success = turtle.forward()
            if success then
                if facing == 1 then
                    this:SetCords(nil,nil,this.Settings.Position.z - 1);
                elseif facing == 2 then
                    this:SetCords(this.Settings.Position.x + 1,nil,nil);
                elseif facing == 3 then
                    this:SetCords(nil,nil,this.Settings.Position.z - 1);
                elseif facing == 4 then
                    this:SetCords(this.Settings.Position.x - 1,nil,nil);
                end
            end
        elseif dir == "backward" then
            local success = turtle.back()
            if success then
                if facing == 1 then
                    this:SetCords(nil,nil,this.Settings.Position.z + 1);
                elseif facing == 2 then
                    this:SetCords(this.Settings.Position.x - 1,nil,nil);
                elseif facing == 3 then
                    this:SetCords(nil,nil,this.Settings.Position.z + 1);
                elseif facing == 4 then
                    this:SetCords(this.Settings.Position.x + 1,nil,nil);
                end
            end
        elseif dir == "up" then
            local success = turtle.up()
            if success then
                this:SetCords(nil,this.Settings.Position.y + 1,nil);
            end
        elseif dir == "down" then
            local success = turtle.down()
            if success then
                this:SetCords(nil,this.Settings.Position.y - 1,nil);
            end
        else
            if facing ~= newFacing then
                if newFacing > facing then
                    local enum = facing;
                    for i=facing, newFacing do
                        enum = enum + 1;
                        turtle.turnRight()
                    end
                    print(enum, newFacing, facing)
                elseif newFacing < facing then
                    local enum = facing;
                    for i=newFacing, facing do
                        enum = enum - 1;
                        turtle.turnLeft()
                    end
                    print(enum, newFacing, facing)
                end
            end
        end

        this.Internal:SaveToFile();
    end

    function this:FindItemName(ItemName)
        for i=1, 16 do
            local detail = turtle.getItemDetail(i);
            if detail ~= nil then
                local name = detail.name;
                if name == ItemName then return i end;
            end
        end
    end

    function this:Refuel()
        if turtle.getFuelLevel() == "unlimited" then
            return
        -- The reason why we do Fuel Limit/2 is just so we don't waste resources
        elseif turtle.getFuelLevel() <= (turtle.getFuelLimit()/2) then
            for i=1, 16 do
                if turtle.getFuelLevel() <= (turtle.getFuelLimit()/2) then break end;
                turtle.select(i)
                if turtle.refuel(0) then -- if it's valid fuel
                    local halfStack = math.ceil(turtle.getItemCount(i)/2) -- work out half of the amount of fuel in the slot
                    turtle.refuel(halfStack) -- consume half the stack as fuel
                end
            end
        end
    end

    _G.TurtleApi = this;

    -- Startup
    this.Internal:LoadFromFile()
    
    if this.Settings.Facing == this.Enum.Facing.Unknown then
        local function getDirection()
            local result, Direction;

            parallel.waitForAny(
                function()
                    io.write("Please enter the direction I'm facing\n")
                    result = io.read()
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
            )

            if result then
                local res = result:lower();
                if res == "n" or res == "north" then
                    Direction = 1;
                elseif res == "e" or res == "east" then
                    Direction = 2;
                elseif res == "s" or res == "south" then
                    Direction = 3;
                elseif res == "w" or res == "west" then
                    Direction = 4;
                else
                    print("Invaild Direction\nVaild Directions: North, East, South, West")
                    return getDirection();
                end
            else
                print("No input found.\nDefaulting to North")
                Direction = 1; -- This is the default since we Don't know the real direction!
            end

            return Direction
        end
        local Dir = getDirection();
        this.Settings.Facing = Dir;
        this.Internal:SaveToFile();
    end
end
