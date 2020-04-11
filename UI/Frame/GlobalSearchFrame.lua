-- GlobalSearchFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2/9/2020, 1:14:38 AM

local setmetatable = setmetatable

---@type ns
local ns = select(2, ...)

local Frame = ns.UI.Frame

---@class tdBag2GlobalSearchFrame: tdBag2Frame
---@field protected Container tdBag2TitleContainer
---@field protected SearchBox tdBag2GlobalSearchBox
local GlobalSearchFrame = ns.Addon:NewClass('UI.GlobalSearchFrame', Frame)

function GlobalSearchFrame:Constructor()
    setmetatable(self.Container.itemButtons, {
        __index = function(t, k)
            t[k] = {}
            return t[k]
        end,
    })

    self.meta.owner = ns.GLOBAL_SEARCH_OWNER
    self.lockOwner = true

    self.OwnerSelector:Hide()
    self.portrait:SetTexture(self.meta.icon)

    ns.UI.GlobalSearchBox:Bind(self.SearchBox)
end