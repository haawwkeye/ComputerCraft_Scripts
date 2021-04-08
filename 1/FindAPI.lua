function CheckForItem(ItemType, ItemSlot)
    local TempIT = ItemType
    local TempTS = ItemSlot
    if ItemType then
        ItemType = string.lower(TempIT)
    end
    if ItemSlot then
        ItemSlot = string.lower(TempTS)
    end

    local Item = peripheral.find(ItemType)
    local hasItem
    if ItemSlot then
        hasItem = (peripheral.isPresent(ItemSlot) and peripheral.getType(ItemSlot) == ItemType)
        return hasItem, (hasItem and peripheral.wrap(ItemSlot) or nil)
    end
    hasItem = (Item ~= nil)

    return hasItem, (hasItem and Item or nil)
end