GameOptionDefinitions = {
    {id = "Autostart", label = "Autostart next round", description = "Off\nFlip 7: Only after Flip 7 reached\nRound: Only everyone stayed/busted\nAlways", type = "selection", default = 4, selection = {"Off", "Flip 7", "Round", "Always"}},
    {id = "AutostartSeconds", label = "Autostart countdown", description = "in seconds", type = "input", default = 5},
    {id = "NextRoundPlayer", label = "Next round starting player", description = "CW: Clockwise\nCCW: Counter-Clockwise\nRandom\nLowest: Player with lowest score\nHighest: Player with highest score", type = "selection", default = 1, selection = {"CW", "CCW", "Random", "Lowest", "Highest"}},
    --{id = "NextGamePlayer", label = "Next game starting player", description = "", type = "selection", default = 1, selection = {"Random", "Next", "Lowest", "Highest"}},
    {id = "Scoreboard", label = "Scoreboard", description = "", type = "bool", default = true},
    {id = "ColoredTokens", label = "Colored tokens", description = "", type = "bool", default = true},
    {id = "ActionBlocker", label = "Action card blocker", description = "", type = "bool", default = true},
    --{id = "CheatMode", label = "Cheat Mode", description = "", type = "bool", default = false},
    --{id = "Debug", label = "Debug Mode", description = "", type = "bool", default = false}
}

-- Config ENUM
CONFIG = {
    AUTOSTART = {
        OFF = 1,
        FLIP7 = 2,
        ROUND = 3,
        ALWAYS = 4
    },
    NEXT_PLAYER = {
        CW = 1,
        CCW = 2,
        RANDOM = 3,
        LOWEST = 4,
        HIGHEST = 5,
    }
}

local Config = {}

function None() end

function Config:constructor(object, savedData)
    self._self = object
    self.visible = false
    self.config = {}
    self.configDefinition = {}

    for _, configData in ipairs(GameOptionDefinitions) do
        self.config[configData.id] = configData.default
        self.configDefinition[configData.id] = configData
    end

    self:loadConfig(savedData)
    self:createToggleButton()
    self:push()
end

function Config:loadConfig(data)
    if data == "" then return end
    data = JSON.decode(data)
    for k, v in pairs(data or {}) do
        if self.configDefinition[k] then
            self.config[k] = v
        end
    end
end

function Config:createButton(params)
    if not params or not params.click_function then print("Invalid params") return false end
    self.buttonData[params.click_function] = self.buttonIndex
    self.buttonIndex = self.buttonIndex + 1
    return self._self.createButton(params)
end

function Config:createInput(params)
    if not params or not params.input_function then print("Invalid params") return false end
    self.inputData[params.input_function] = self.inputIndex
    self.inputIndex = self.inputIndex + 1
    return self._self.createInput(params)
end

function Config:clear()
    self._self.clearButtons()
    self._self.clearInputs()

    self.buttonIndex, self.inputIndex = 0, 0
    self.buttonData, self.inputData = {}, {}
end

function Config:createToggleButton()
    self:clear()

    self:createButton({
        click_function = "ToggleConfigPanel",
        function_owner = self._self,
        label          = "Configurations",
        position       = {0, 0.25, 0},
        rotation       = {0, 180, 0},
        scale          = {0.4, 1, 0.4},
        width          = 4000,
        height         = 1000,
        color          = "White",
        font_color     = "Black",
        font_size      = 600,
    })

    self.visible = false
end

function Config:toggleConfigPanel()
    if self.visible then return self:createToggleButton() end

    local offset = 0
    for i, configData in ipairs(GameOptionDefinitions) do
        local option = configData.id

        -- Labels
        self:createButton({
            click_function = "None",
            function_owner = self._self,
            label          = configData.label,
            position       = {0, 0.25, -2 - offset*1},
            rotation       = {0, 180, 0},
            scale          = {0.35, 1, 0.35},
            width          = 0,
            height         = 0,
            font_color     = "White",
            font_size      = 1500,
        })

        local position = {-5, 0.25, -2 - offset*1}
        local value = self.config[option]

        if configData.type == "bool" then
            self:createButton({
                click_function = option,
                function_owner = self._self,
                label          = value and string.char(10008) or "",
                tooltip        = configData.description or "",
                position       = position,
                rotation       = {0, 180, 0},
                scale          = {0.35, 1, 0.35},
                width          = 1000,
                height         = 1000,
                font_color     = "Black",
                font_size      = 2000,
            })

        elseif configData.type == "input" then
            self:createInput({
                label           = "",
                tooltip        = configData.description or "",
                input_function  = option,
                function_owner  = self._self,
                validation      = 2,
                alignment       = 3,
                position        = position,
                rotation        = {0, 180, 0},
                scale           = {0.35, 1, 0.35},
                width           = 1500,
                height          = 1000,
                font_size       = 1200,
                font_color      = "Black",
                value           = value,
            })

        elseif configData.type == "selection" then
            self:createButton({
                click_function = option,
                function_owner = self._self,
                label          = configData.selection[value],
                tooltip        = configData.description or "",
                position       = position,
                rotation       = {0, 180, 0},
                scale          = {0.35, 1, 0.35},
                width          = 4000,
                height         = 1000,
                font_color     = "Black",
                font_size      = 2000,
            })

        end

        offset = offset + 1
    end

    self.visible = true
end

function Config:inputEdit(button, object, color, input, stillEditing)
    if stillEditing then return end
    if self.config[button] == nil then return end

    local index = self.buttonData[button]
    local input = tonumber(input)

    if input then
        local fixedinput = math.max(math.min(input, 10), 1)

        self.config[button] = fixedinput
        self:push()

        if fixedinput ~= input then
            self._self.editInput({index = index, value = tostring(self.config[button])})
        end
    else
        self._self.editInput({index = index, value = tostring(self.config[button])})
    end
end

function Config:toggleCheckbox(button, object, color, alt)
    if alt then return end
    if self.config[button] == nil then return end

    local index = self.buttonData[button]
    self.config[button] = not self.config[button]
    self._self.editButton({index = index, label = self.config[button] and string.char(10008) or ""})
    self:push()
end

function Config:toggleSelection(button, object, color, alt)
    if alt then return end
    if self.config[button] == nil then return end

    local index = self.buttonData[button]
    self.config[button] = self.config[button] + 1
    if self.config[button] > #self.configDefinition[button].selection then self.config[button] = 1 end
    local next = self.configDefinition[button].selection[self.config[button]]

    self._self.editButton({index = index, label = next})
    self:push()
end

function Config:push()
    Global.call("UpdateGameOptions", self.config)
end

-- Wrapper functions
function ToggleConfigPanel(...) return config:toggleConfigPanel(...) end
for _, v in ipairs(GameOptionDefinitions) do if v.type == "input" then _G[v.id] = function(...) return config:inputEdit(v.id, ...) end end end
for _, v in ipairs(GameOptionDefinitions) do if v.type == "selection" then _G[v.id] = function(...) return config:toggleSelection(v.id, ...) end end end
for _, v in ipairs(GameOptionDefinitions) do if v.type == "bool" then _G[v.id] = function(...) return config:toggleCheckbox(v.id, ...) end end end

-- Events
function onLoad(savedData)
    Global.setTable("CONFIG", CONFIG)
    config = new(Config, self, savedData)
end

function onSave()
    if config and config.config then
        return JSON.encode(config.config or {})
    end
end

-- Utils
-- class (credits sbx320/classlib)
function new(class, ...)
	assert(type(class) == "table", "first argument provided to new is not a table")

	local instance = setmetatable({},
		{
			__index = class;
			__super = { class };
			__newindex = class.__newindex;
			__call = class.__call;
			__len = class.__len;
			__unm = class.__unm;
			__add = class.__add;
			__sub = class.__sub;
			__mul = class.__mul;
			__div = class.__div;
			__pow = class.__pow;
			__concat = class.__concat;		
		})

	if rawget(class, "constructor") then rawget(class, "constructor")(instance, ...) end
	instance.constructor = false

	return instance
end