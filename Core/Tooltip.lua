-- Tooltip.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/24/2019, 1:03:40 PM

local ipairs = ipairs

---@type ns
local ns = select(2, ...)
local L = ns.L
local Cache = ns.Cache

local Tooltip = ns.Addon:NewModule('Tooltip', 'AceHook-3.0')
Tooltip:Disable()
Tooltip.APIS = {
    'SetMerchantItem', 'SetBuybackItem', 'SetBagItem', 'SetAuctionItem', 'SetAuctionSellItem', 'SetLootItem',
    'SetLootRollItem', 'SetInventoryItem', 'SetTradePlayerItem', 'SetTradeTargetItem', 'SetQuestItem',
    'SetQuestLogItem', 'SetInboxItem', 'SetSendMailItem', 'SetHyperlink', 'SetCraftItem', 'SetTradeSkillItem',
}
Tooltip.LABELS = { --
    L['Equipped'], L['Inventory'], L['Bank'],
}
Tooltip.EMPTY = {}

function Tooltip:OnInitialize()
    self.cache = {}

    C_Timer.After(0, function()
        self:Update()
    end)
end

function Tooltip:Update()
    if ns.Addon.db.profile.tipCount then
        self:Enable()
    else
        self:Disable()
    end
end

function Tooltip:OnEnable()
    self:HookTip(GameTooltip)
    self:HookTip(ItemRefTooltip)
end

function Tooltip:HookTip(tip)
    for _, api in ipairs(self.APIS) do
        self:SecureHook(tip, api, 'OnTooltipItem')
    end

    for _, shoppingTip in ipairs(tip.shoppingTooltips) do
        self:SecureHook(shoppingTip, 'SetCompareItem', 'OnCompareItem')
    end
end

function Tooltip:OnCompareItem(tip1, tip2)
    self:OnTooltipItem(tip1)
    self:OnTooltipItem(tip2)
end

function Tooltip:OnTooltipItem(tip)
    local _, item = tip:GetItem()
    if not item then
        return
    end
    local itemId = tonumber(item and item:match('item:(%d+)'))
    if itemId and itemId ~= HEARTHSTONE_ITEM_ID then
        self:AddOwners(tip, itemId)
        tip:Show()
    end
end

function Tooltip:AddOwners(tip, item)
    for owner in Cache:IterateOwners() do
        local info = self:GetOwnerItemInfo(owner, item)
        if info and info.total then
            local r, g, b = info.color.r, info.color.g, info.color.b
            tip:AddDoubleLine(info.name, info.text, r, g, b, r, g, b)
        end
    end
end

function Tooltip:GetCounts(...)
    local places = 0
    local total = 0
    local sb = {}
    for i = 1, select('#', ...) do
        local count = select(i, ...)
        local label = self.LABELS[i]

        if count > 0 then
            places = places + 1
            total = total + count

            tinsert(sb, format('%s:%d', label, count))
        end
    end

    local text = table.concat(sb, ' ')

    if places > 1 then
        return total, format('%d |cffaaaaaa(%s)|r', total, text)
    elseif places == 1 then
        return total, text
    end
end

function Tooltip:GetOwnerItemInfo(owner, itemId)
    local cache = self.cache[owner] and self.cache[owner][itemId]
    if cache then
        return cache
    end

    local info = Cache:GetOwnerInfo(owner)
    local equip = self:GetBagItemCount(owner, 'equip', itemId)
    local bags, banks = 0, 0

    if info.cached then
        for bag in ipairs(ns.GetBags(ns.BAG_ID.BAG)) do
            bags = bags + self:GetBagItemCount(owner, bag, itemId)
        end
        for bag in ipairs(ns.GetBags(ns.BAG_ID.BANK)) do
            banks = banks + self:GetBagItemCount(owner, bag, itemId)
        end
    else
        local owned = GetItemCount(itemId, true)
        local carrying = GetItemCount(itemId)

        bags = carrying - equip
        banks = owned - carrying
    end

    local total, text = self:GetCounts(equip, bags, banks)
    local item
    if total then
        item = { --
            name = info.name,
            text = text,
            total = total,
            color = RAID_CLASS_COLORS[info.class or 'PRIEST'],
        }
    else
        item = self.EMPTY
    end

    if info.cached then
        self.cache[owner] = self.cache[owner] or {}
        self.cache[owner][itemId] = item
    end
    return item
end

function Tooltip:GetBagItemCount(owner, bag, itemId)
    local count = 0
    local info = Cache:GetBagInfo(owner, bag)

    for slot = 1, info.count or 0 do
        local id = Cache:GetItemID(owner, bag, slot)
        if id == itemId then
            count = count + (Cache:GetItemInfo(owner, bag, slot).count or 1)
        end
    end
    return count
end