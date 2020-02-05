-- Api.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/18/2019, 1:11:20 PM

---- LUA
local pairs = pairs
local select = select
local format = string.format
local tinsert = table.insert
local tonumber = tonumber

---- WOW
local C_Timer = C_Timer
local ContainerIDToInventoryID = ContainerIDToInventoryID
local GetScreenHeight = GetScreenHeight
local GetScreenWidth = GetScreenWidth
local PlaySound = PlaySound

---- UI
local GameTooltip = GameTooltip

---- G
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local BACKPACK_CONTAINER = BACKPACK_CONTAINER
local BANK_CONTAINER = BANK_CONTAINER
local KEYRING_CONTAINER = KEYRING_CONTAINER
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local NUM_BANKBAGSLOTS = NUM_BANKBAGSLOTS
local EQUIP_CONTAINER = 'equip'
local MAIL_CONTAINER = 'mail'
local COD_CONTAINER = 'cod'

---@type ns
local ns = select(2, ...)

ns.EQUIP_CONTAINER = EQUIP_CONTAINER
ns.MAIL_CONTAINER = MAIL_CONTAINER
ns.COD_CONTAINER = COD_CONTAINER

ns.ITEM_SIZE = 37
ns.ITEM_SPACING = 2

ns.SECONDS_OF_DAY = 24 * 60 * 60

ns.LEFT_MOUSE_BUTTON = [[|TInterface\TutorialFrame\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283|t]]
ns.RIGHT_MOUSE_BUTTON = [[|TInterface\TutorialFrame\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385|t]]

ns.RACE_ICON_TCOORDS = {
    ['HUMAN_MALE'] = {0, 0.25, 0, 0.25},
    ['DWARF_MALE'] = {0.25, 0.5, 0, 0.25},
    ['GNOME_MALE'] = {0.5, 0.75, 0, 0.25},
    ['NIGHTELF_MALE'] = {0.75, 1.0, 0, 0.25},

    ['TAUREN_MALE'] = {0, 0.25, 0.25, 0.5},
    ['SCOURGE_MALE'] = {0.25, 0.5, 0.25, 0.5},
    ['TROLL_MALE'] = {0.5, 0.75, 0.25, 0.5},
    ['ORC_MALE'] = {0.75, 1.0, 0.25, 0.5},

    ['HUMAN_FEMALE'] = {0, 0.25, 0.5, 0.75},
    ['DWARF_FEMALE'] = {0.25, 0.5, 0.5, 0.75},
    ['GNOME_FEMALE'] = {0.5, 0.75, 0.5, 0.75},
    ['NIGHTELF_FEMALE'] = {0.75, 1.0, 0.5, 0.75},

    ['TAUREN_FEMALE'] = {0, 0.25, 0.75, 1.0},
    ['SCOURGE_FEMALE'] = {0.25, 0.5, 0.75, 1.0},
    ['TROLL_FEMALE'] = {0.5, 0.75, 0.75, 1.0},
    ['ORC_FEMALE'] = {0.75, 1.0, 0.75, 1.0},
}

ns.TOKENS = {20560, 20559, 20558}

-- @debug@
---@type L
local L = LibStub('AceLocale-3.0'):GetLocale('tdBag2')
-- @end-debug@
--[===[@non-debug@
local L = LibStub('AceLocale-3.0'):GetLocale('tdBag2', true)
--@end-non-debug@]===]
ns.L = L

local BAG_ID = { --
    BAG = 'bag',
    BANK = 'bank',
    MAIL = 'mail',
}

local BAG_ICONS = { --
    [BAG_ID.BAG] = [[Interface\Buttons\Button-Backpack-Up]],
    [BAG_ID.BANK] = [[Interface\ICONS\INV_Misc_Bag_13]],
    [BAG_ID.MAIL] = [[Interface\MailFrame\Mail-Icon]],
}

local BAG_TITLES = { --
    [BAG_ID.BAG] = L.TITLE_BAG,
    [BAG_ID.BANK] = L.TITLE_BANK,
    [BAG_ID.MAIL] = L.TITLE_MAIL,
}

local BAGS = { --
    [BAG_ID.BAG] = {BACKPACK_CONTAINER},
    [BAG_ID.BANK] = {BANK_CONTAINER},
    [BAG_ID.MAIL] = {MAIL_CONTAINER, COD_CONTAINER},
}

local BAG_CLASSES = { --
    [BAG_ID.BAG] = 'Inventory',
    [BAG_ID.BANK] = 'Bank',
    [BAG_ID.MAIL] = 'Mail',
}

local BAG_TEMPLATES = { --
    [BAG_ID.BAG] = 'tdBag2FrameTemplate',
    [BAG_ID.BANK] = 'tdBag2FrameTemplate',
    [BAG_ID.MAIL] = 'tdBag2BaseFrameTemplate',
}

local BAG_SETS = {}
local INV_IDS = {}
local BAG_IDS = {}
do
    local function touch(bag, bagId)
        local slot = ContainerIDToInventoryID(bag)
        INV_IDS[slot] = bag
        BAG_IDS[bag] = slot

        tinsert(BAGS[bagId], bag)
    end

    for i = 1, NUM_BAG_SLOTS do
        touch(i, BAG_ID.BAG)
    end
    for i = 1, NUM_BANKBAGSLOTS do
        touch(i + NUM_BAG_SLOTS, BAG_ID.BANK)
    end

    tinsert(BAGS[BAG_ID.BAG], KEYRING_CONTAINER)

    for bagId, v in pairs(BAGS) do
        for _, bag in pairs(v) do
            BAG_SETS[bag] = bagId
        end
    end
end

ns.BAG_ID = BAG_ID
ns.BAG_ICONS = BAG_ICONS
ns.BAG_TITLES = BAG_TITLES
ns.BAG_CLASSES = BAG_CLASSES
ns.BAG_TEMPLATES = BAG_TEMPLATES

ns.PLAYER = nil
ns.REALM = nil

ns.BAG_FAMILY_KEYS = { --
    [1] = 'colorQuiver',
    [2] = 'colorQuiver',
    [3] = 'colorSoul',
    [4] = 'colorSoul',
    [6] = 'colorHerb',
    [7] = 'colorEnchant',
    [9] = 'colorKeyring',
}

ns.TRADE_BAG_ORDER = { --
    NONE = 'none',
    TOP = 'top',
    BOTTOM = 'bottom',
}

ns.FRAME_OPTION_EVENTS = { --
    bagFrame = 'BAG_FRAME_TOGGLED',
    managed = 'MANAGED_TOGGLED',
    tokenFrame = 'TOKEN_FRAME_TOGGLED',
    pluginButtons = 'PLUGIN_FRAME_TOGGLED',

    scale = 'CONTAINER_LAYOUT',
    column = 'CONTAINER_LAYOUT',
    reverseSlot = 'CONTAINER_LAYOUT',

    reverseBag = 'BAG_ORDER_CHANGED',
    tradeBagOrder = 'BAG_ORDER_CHANGED',

    iconCharacter = 'ICON_CHARACTER_TOGGLED',
    remainLimit = 'REMAIN_LIMIT_CHANGED',
}

ns.OPTION_EVENTS = { --
    textOffline = 'TEXT_OFFLINE_TOGGLED',

    iconJunk = 'ITEM_BORDER_UPDATE',
    iconQuestStarter = 'ITEM_BORDER_UPDATE',
    glowQuest = 'ITEM_BORDER_UPDATE',
    glowUnusable = 'ITEM_BORDER_UPDATE',
    glowQuality = 'ITEM_BORDER_UPDATE',
    glowEquipSet = 'ITEM_BORDER_UPDATE',
    glowNew = 'ITEM_BORDER_UPDATE',
    glowAlpha = 'ITEM_BORDER_UPDATE',

    colorSlots = 'ITEM_COLOR_UPDATE',
    colorNormal = 'ITEM_COLOR_UPDATE',
    colorQuiver = 'ITEM_COLOR_UPDATE',
    colorSoul = 'ITEM_COLOR_UPDATE',
    colorEnchant = 'ITEM_COLOR_UPDATE',
    colorHerb = 'ITEM_COLOR_UPDATE',
    colorKeyring = 'ITEM_COLOR_UPDATE',
    emptyAlpha = 'ITEM_COLOR_UPDATE',

    tipCount = function()
        return ns.Tooltip:Update()
    end,
}

local function riter(t, i)
    i = i - 1
    if i > 0 then
        return i, t[i]
    end
end

function ns.ripairs(t)
    return riter, t, #t + 1
end

function ns.GetBags(bagId)
    return BAGS[bagId]
end

function ns.GetBagId(bag)
    return BAG_SETS[bag]
end

function ns.IsInBag(bag)
    return BAG_SETS[bag] == BAG_ID.BAG
end

function ns.IsInBank(bag)
    return BAG_SETS[bag] == BAG_ID.BANK
end

function ns.IsBackpack(bag)
    return bag == BACKPACK_CONTAINER
end

function ns.IsBank(bag)
    return bag == BANK_CONTAINER
end

function ns.IsKeyring(bag)
    return bag == KEYRING_CONTAINER
end

function ns.IsEquip(bag)
    return bag == EQUIP_CONTAINER
end

function ns.IsMail(bag)
    return bag == MAIL_CONTAINER
end

function ns.IsBaseBag(bag)
    return ns.IsBackpack(bag) or ns.IsBank(bag) or ns.IsKeyring(bag)
end

function ns.IsCustomBag(bag)
    return ns.IsContainerBag(bag) and bag > BACKPACK_CONTAINER
end

function ns.IsContainerBag(bag)
    return tonumber(bag)
end

function ns.SlotToBag(inv)
    return INV_IDS[inv]
end

function ns.BagToSlot(bag)
    return BAG_IDS[bag]
end

function ns.IsSelf(owner)
    return not owner or owner == ns.PLAYER
end

function ns.AnchorTooltip(frame)
    if frame:GetRight() >= (GetScreenWidth() / 2) then
        GameTooltip:SetOwner(frame, 'ANCHOR_LEFT')
    else
        GameTooltip:SetOwner(frame, 'ANCHOR_RIGHT')
    end
end

function ns.AnchorTooltip2(frame, anchor, x, y)
    GameTooltip:SetOwner(frame, 'ANCHOR_NONE')
    if frame:GetTop() > (GetScreenHeight() / 2) then
        GameTooltip:SetPoint('TOP' .. anchor, frame, 'BOTTOM' .. anchor, x, y)
    else
        GameTooltip:SetPoint('BOTTOM' .. anchor, frame, 'TOP' .. anchor, x, y)
    end
end

function ns.PlayToggleSound(flag)
    return PlaySound(flag and 856 or 857)
end

function ns.GetOwnerColoredName(owner)
    local color = RAID_CLASS_COLORS[owner.class or 'PRIEST']
    return format('|cff%02x%02x%02x%s|r', color.r * 0xFF, color.g * 0xFF, color.b * 0xFF, owner.name)
end

function ns.LeftButtonTip(text)
    return ns.LEFT_MOUSE_BUTTON .. text, 1, 1, 1
end

function ns.RightButtonTip(text)
    return ns.RIGHT_MOUSE_BUTTON .. text, 1, 1, 1
end

function ns.Spawned(method)
    return function(a1, a2, a3, a4, a5, a6, a7, a8, a9)
        return C_Timer.After(0, function()
            return method(a1, a2, a3, a4, a5, a6, a7, a8, a9)
        end)
    end
end

function ns.NameGenerator(name)
    local index = 0
    return function()
        index = index + 1
        return name .. index
    end
end
