local inputValue = ""

function onLoad(saved_data)
    if saved_data ~= "" then
        local data = JSON.decode(saved_data)
        inputValue = data.inputValue or ""
    end

    createInputField()
end

function createInputField()
    self.clearInputs()

    self.createInput({
        input_function = "onInputChanged",
        function_owner = self,

        value      = inputValue,
        alignment  = 3,
        position   = {0, 0.3, 0},
        width      = 800,
        height     = 600,
        rotation   = {0, 0, 0},
        font_size  = 400,
        scale      = {1, 1, 1},
        font_color = {0,0,0,99},
        color      = {1,1,1,0},
        tab        = 2
    })
end

function onInputChanged(obj, ply, value, selected)
    inputValue = value
    saveData()
end

function saveData()
    self.script_state = JSON.encode({
        inputValue = inputValue
    })
end