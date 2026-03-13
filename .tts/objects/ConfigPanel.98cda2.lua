GameOptionDefinitions = {
    UseAutoRestart = {type = "bool", default = true},
    AutoRestartSeconds = {type = "input", default = 5},
    ColorTintTokens = {type = "bool", default = true},
    Scoreboard = {type = "bool", default = true},
    NextStartingPlayer = {type = "selection", default = 1, selection = {"Random", "Next", "Lowest", "Highest"}},
    ActionCardBlocker = {type = "bool", default = true},
    CheatMode = {type = "bool", default = false},
    Debug = {type = "bool", default = false}
}

local Config = {}

function onSave()
    --return JSON.encode({})
end

function onLoad(savedData)
    config = new(Config, self)
end

function None() end

function Config:constructor(object)
    self._self = object
    self.visible = false
    self.config = {}

    self:createToggleButton()
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
        scale          = {0.2, 1, 0.2},
        width          = 4000,
        height         = 1000,
        color          = "White",
        font_color     = "Black",
        font_size      = 500,
    })

    self.visible = false
end

function Config:toggleConfigPanel()
    if self.visible then return self:createToggleButton() end

    local offset = 0
    for option, configData in pairs(GameOptionDefinitions) do
        -- Labels
        self:createButton({
            click_function = "None",
            function_owner = self._self,
            label          = option,
            position       = {0, 0.25, -1 - offset*0.5},
            rotation       = {0, 180, 0},
            scale          = {0.2, 1, 0.2},
            width          = 0,
            height         = 0,
            font_color     = "White",
            font_size      = 1500,
        })

        if self.config[option] == nil then
            self.config[option] = configData.default
        end

        local position = {-3, 0.25, -1 - offset * 0.5}
        local value = self.config[option]

        if configData.type == "bool" then
            self:createButton({
                click_function = option,
                function_owner = self._self,
                label          = value and string.char(10008) or "",
                position       = position,
                rotation       = {0, 180, 0},
                scale          = {0.2, 1, 0.2},
                width          = 1000,
                height         = 1000,
                font_color     = "Black",
                font_size      = 2000,
            })

        elseif configData.type == "input" then
            self:createInput({
                label           = "",
                input_function  = option,
                function_owner  = self._self,
                validation      = 2,
                alignment       = 3,
                position        = position,
                rotation        = {0, 180, 0},
                scale           = {0.2, 1, 0.2},
                width           = 1500,
                height          = 1000,
                font_size       = 1200,
                font_color      = "Black",
                tooltip         = "",
                value           = value,
            })

        elseif configData.type == "selection" then
            self:createButton({
                click_function = option,
                function_owner = self._self,
                label          = configData.selection[value],
                position       = position,
                rotation       = {0, 180, 0},
                scale          = {0.2, 1, 0.2},
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

        print("Previous: ", self.config[button])
        self.config[button] = fixedinput
        print("New: ", self.config[button])

        if fixedinput ~= input then
            self._self.editInput({index = index, value = tostring(self.config[button])})
        end
    else
        print("Reset: ", self.config[button])
        self._self.editInput({index = index, value = tostring(self.config[button])})
    end
end

function Config:toggleCheckbox(button, object, color, alt)
    if alt then return end
    if self.config[button] == nil then return end

    local index = self.buttonData[button]
    self.config[button] = not self.config[button]
    self._self.editButton({index = index, label = self.config[button] and string.char(10008) or ""})

    print("Click: ", button)
end

function Config:toggleSelection(button, object, color, alt)
    if alt then return end
    if self.config[button] == nil then return end

    local index = self.buttonData[button]
    self.config[button] = self.config[button] + 1
    if self.config[button] > #GameOptionDefinitions[button].selection then self.config[button] = 1 end
    local next = GameOptionDefinitions[button].selection[self.config[button]]

    self._self.editButton({index = index, label = next})
end

-- Wrapper functions
function ToggleConfigPanel(...) return config:toggleConfigPanel(...) end
for k, v in pairs(GameOptionDefinitions) do if v.type == "input" then _G[k] = function(...) return config:inputEdit(k, ...) end end end
for k, v in pairs(GameOptionDefinitions) do if v.type == "selection" then _G[k] = function(...) return config:toggleSelection(k, ...) end end end
for k, v in pairs(GameOptionDefinitions) do if v.type == "bool" then _G[k] = function(...) return config:toggleCheckbox(k, ...) end end end

-- Utils
-- lass (credits sbx320/classlib)
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