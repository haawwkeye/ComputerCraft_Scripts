do
    local self = {};

    function self:FindItemName(ItemName)
        for i=1, 16 do
            local detail = turtle.getItemDetail(i);
            print(detail)
        end
    end

    function self:Refuel()
        if turtle.getFuelLevel() == "unlimited" then
            return
        elseif turtle.getFuelLevel() <= (turtle.getFuelLimit()/2) then
            self
        end
    end

    _G.TurtleApi = self;
end