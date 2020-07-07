-- Upvalues
local GetMoney, LibStub = GetMoney, LibStub
local AceGUI = LibStub("AceGUI-3.0")
local media = LibStub("LibSharedMedia-3.0")

---@type ZxStartingGold
local ZxStartingGold = LibStub("AceAddon-3.0"):GetAddon("ZxStartingGold")
---@type FramePool47
local FramePool47 = ZxStartingGold.FramePool47
---@type CoreOptions47
local CoreOptions47 = ZxStartingGold.optionTables["CoreOptions47"]

local MODULE_NAME = "GoldOptions"
local DECORATIVE_NAME = "Gold Options"

---@class GoldOptions
local GoldOptions = ZxStartingGold:NewModule(MODULE_NAME)
GoldOptions.MODULE_NAME = MODULE_NAME
GoldOptions.DECORATIVE_NAME = DECORATIVE_NAME

function GoldOptions:__init__()
  self.options = {}
  self._initCopperAmount = 0
  self._goldFrame = nil
  ---@type CoreOptions47
  self._coreOptions47 = CoreOptions47:new(self)
end

---do init tasks here, like loading the Saved Variables,
---or setting up slash commands.
function GoldOptions:OnInitialize()
  self._defaults = {profile = {font = "PT Mono", fontsize = 24}}

  self.db = ZxStartingGold.db:RegisterNamespace(MODULE_NAME, self._defaults)
  self:__init__()

  self:registerModuleOptionsTable()
  self:SetEnabledState(ZxStartingGold:getModuleEnabledState(MODULE_NAME))
end

---Do more initialization here, that really enables the use of your addon.
---Register Events, Hook functions, Create Frames, Get information from
---the game that wasn't available in OnInitialize
function GoldOptions:OnEnable() self:_setInitMoneyAmount() end

---Unhook, Unregister Events, Hide frames that you created.
---You would probably only use an OnDisable if you want to 
---build a "standby" mode, or be able to toggle modules on/off.
function GoldOptions:OnDisable() end

function GoldOptions:registerModuleOptionsTable()
  ZxStartingGold:registerModuleOptions(self.MODULE_NAME, self:getOptionTable(),
    self.DECORATIVE_NAME)
end

function GoldOptions:refreshConfig()
  if self._goldFrame ~= nil then
    for _, fontString in ipairs(self._goldFrame.goldTextList) do
      fontString:SetFont(media:Fetch("font", self.db.profile.font), self.db.profile.fontsize,
        "OUTLINE")
    end
  end
end

function GoldOptions:getOptionTable()
  if next(self.options) == nil then
    self.options = {
      type = "group",
      name = self.DECORATIVE_NAME,
      get = function(info) return self._coreOptions47:getOption(info) end,
      set = function(info, value) self._coreOptions47:setOption(info, value) end,
      args = {
        font = {
          name = "Font",
          type = "select",
          dialogControl = "LSM30_Font",
          values = media:HashTable("font"),
          order = 10
        },
        fontsize = {
          name = "Font Size",
          desc = "Font Size",
          type = "range",
          min = 10,
          max = 36,
          step = 1,
          order = self._coreOptions47:incrementOrderIndex()
        },
        getMoneyButton = {
          type = "execute",
          name = "Get Money Difference",
          order = 11,
          func = function(curFrame, ...)
            local curMoney = GetMoney()
            local strList = {
              "INITIAL AMOUNT", self:_getMoneyString(self._initCopperAmount), "", "NEW AMOUNT",
              self:_getMoneyString(curMoney), "", "DIFFERENCE",
              self:_getMoneyString(curMoney - self._initCopperAmount)
            }

            local str2 = ""
            for _, str1 in ipairs(strList) do str2 = str2 .. str1 .. "\n" end
            self.options.args.moneyDescription.name = str2

            self:_openGoldFrame(strList)
          end
        },
        moneyDescription = {type = "description", name = "", order = 12, fontSize = "large"}
      }
    }
  end
  return self.options
end

-- ########################################################
-- # PRIVATE FUNCTIONS
-- ########################################################
function GoldOptions:_setInitMoneyAmount()
  local frame = FramePool47:getFrame()
  -- Ref: https://wow.gamepedia.com/API_GetMoney
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:SetScript("OnEvent", function(curFrame, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
      self:_handlePlayerEnteringWorld()
      frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
      frame:SetScript("OnEvent", nil)
      FramePool47:releaseFrame(frame)
    end
  end)
end

function GoldOptions:_handlePlayerEnteringWorld() self._initCopperAmount = GetMoney() end

---@param copperAmount number
---@return string
function GoldOptions:_getMoneyString(copperAmount)
  local sign = ""
  if copperAmount < 0 then
    sign = "-"
    copperAmount = math.abs(copperAmount)
  end

  local gold = copperAmount / 100 / 100
  local silver = (copperAmount / 100) % 100
  local copper = copperAmount % 100
  local goldColor = "|c00" .. "ffff00"
  local silverColor = "|c00" .. "a9a6a9"
  local copperColor = "|c00" .. "a1613a"
  local whiteColor = "|c00" .. "ffffff"
  return string.format("%s%s%4d Gold, %s%2d Silver, %s%2d Copper%s", sign, goldColor, gold,
           silverColor, silver, copperColor, copper, whiteColor)
end

---@param strList table<integer, string>
function GoldOptions:_openGoldFrame(strList)
  if self._goldFrame == nil then
    self._aceguiFrame = AceGUI:Create("Frame")
    self._aceguiFrame:SetTitle("Gold Difference")
    -- Do not release, otherwise other frames will have the gold difference text in the background
    -- self._aceguiFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)

    self._goldFrame = self._aceguiFrame.frame
    self._goldFrame.goldTextList = {}
  end

  for index, str1 in ipairs(strList) do
    local fontString = self._goldFrame:CreateFontString(nil, "OVERLAY")
    fontString:SetFont(media:Fetch("font", self.db.profile.font), self.db.profile.fontsize,
      "OUTLINE")
    if index == 1 then
      fontString:SetPoint("TOPLEFT", self._goldFrame, "TOPLEFT", 20, -30)
    else
      fontString:SetPoint("TOPLEFT", self._goldFrame.goldTextList[index - 1], "BOTTOMLEFT", 0,
        -2)
    end
    if str1 == "" then str1 = " " end
    fontString:SetText(str1)
    table.insert(self._goldFrame.goldTextList, fontString)
  end

  if not self._goldFrame:IsVisible() then self._goldFrame:Show() end
end
