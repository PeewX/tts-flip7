local inputValue = ""

function onLoad(saved_data)
    if saved_data ~= "" then
        local data = JSON.decode(saved_data)
        inputValue = data.inputValue or ""
    end

    CreateInputField()
end

function CreateInputField()
    self.clearInputs()

    self.createInput({
        input_function = "SaveInput",
        function_owner = self,
        validation = 2,
        value      = inputValue,
        alignment  = 3,
        position   = {0, 0.3, 0},
        width      = 800,
        height     = 600,
        rotation   = {0, 0, 0},
        font_size  = 400,
        scale      = {1, 1, 1},
        font_color = {0, 0, 0, 99},
        color      = {1, 1, 1, 0},
        tab        = 2
    })
end

function SaveInput(object, color, value, selected)
    if tonumber(value) then
        JSON.encode({inputValue = math.floor(value)})
    end
end