-- MoneyFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/19/2019, 1:52:03 AM

---- LUA
local _G = _G
local select = select

---- WOW
local GetMoneyString = GetMoneyString
local MoneyFrame_Update = MoneyFrame_Update
local MoneyInputFrame_OpenPopup = MoneyInputFrame_OpenPopup
local MoneyFrame_UpdateTrialErrorButton = MoneyFrame_UpdateTrialErrorButton

---- UI
local GameTooltip = GameTooltip

---@type ns
local ns = select(2, ...)
local L = ns.L
local Cache = ns.Cache

---@class tdBag2MoneyFrame: Button
---@field private meta tdBag2FrameMeta
local MoneyFrame = ns.Addon:NewClass('UI.MoneyFrame', 'Button')

MoneyFrame.GenerateName = ns.NameGenerator('tdBag2MoneyFrame')

function MoneyFrame:Constructor(_, meta)
    self.meta = meta

    self.Money = CreateFrame('Frame', self:GenerateName(), self, 'SmallMoneyFrameTemplate')
    self.Money.trialErrorButton:SetPoint('LEFT', 8, 1)
    self.Money:SetScript('OnEvent', nil)
    self.Money:SetScript('OnShow', nil)
    self.Money:UnregisterAllEvents()
    self.Money:SetAllPoints(self)

    local name = self.Money:GetName()
    _G[name .. 'GoldButton']:EnableMouse(false)
    _G[name .. 'SilverButton']:EnableMouse(false)
    _G[name .. 'CopperButton']:EnableMouse(false)

    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.UnregisterAllEvents)
    self:SetScript('OnEnter', self.OnEnter)
    self:SetScript('OnLeave', self.OnLeave)
    self:SetScript('OnClick', self.OnClick)
end

function MoneyFrame:OnShow()
    if not self.meta:IsCached() then
        self:RegisterEvent('PLAYER_MONEY', 'Update')
        self:RegisterEvent('PLAYER_TRADE_MONEY', 'Update')
        self:RegisterEvent('SEND_MAIL_MONEY_CHANGED', 'Update')
        self:RegisterEvent('SEND_MAIL_COD_CHANGED', 'Update')
    else
        self:UnregisterAllEvents()
    end
    self:RegisterFrameEvent('FRAME_OWNER_CHANGED', 'OnShow')
    self:Update()
end

function MoneyFrame:Update()
    if self.meta:IsCached() then
        local money = Cache:GetOwnerInfo(self.meta.owner).money or 0
        MoneyFrame_Update(self.Money:GetName(), money, money == 0)
    else
        MoneyFrame_UpdateMoney(self.Money)
    end
end

function MoneyFrame:OnEnter()
    local total = 0
    for name in Cache:IterateOwners() do
        local owner = Cache:GetOwnerInfo(name)
        dump(owner)
        if not owner.isguild and owner.money then
            total = total + owner.money
        end
    end

    ns.AnchorTooltip2(self, 'RIGHT')
    GameTooltip:AddDoubleLine(L['Total'], GetMoneyString(total, true), nil, nil, nil, 1, 1, 1)
    GameTooltip:AddLine(' ')

    for name in Cache:IterateOwners() do
        local owner = Cache:GetOwnerInfo(name)
        if not owner.isguild and owner.money then
            local name = ns.GetOwnerColoredName(owner)
            local coins = GetMoneyString(owner.money, true)

            GameTooltip:AddDoubleLine(name, coins, 1, 1, 1, 1, 1, 1)
        end
    end

    GameTooltip:Show()
end

function MoneyFrame:OnClick()
    MoneyInputFrame_OpenPopup(self.Money)
end

function MoneyFrame:OnLeave()
    GameTooltip:Hide()
end
