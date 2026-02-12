-- Globals
PLAYER_COLORS = {"Yellow", "Red", "White", "Orange", "Blue", "Pink", "Green", "Purple"}

function onLoad()
    StartBtn = getObjectFromGUID("5324c0")
    HitBtn = getObjectFromGUID("e7358b")
    StayBtn = getObjectFromGUID("83c6d4")

    Scale = StartBtn.getScale()
    Bound = StartBtn.getBoundsNormalized()

    StartBtn.createButton({
        click_function = "startgame",
        function_owner = self,
        label          = "Reset",
        position       = {0, 0.5, 0},
        rotation       = {0, 180, 0},
        scale          = {0.4/Scale.x, 1, 0.4/Scale.z},
        width          = 1200*Bound.size.x,
        height         = 800*Bound.size.z,
        color          = "White",
        font_color     = "Black",
        font_size      = 700*Bound.size.z
    })

    HitBtn.createButton({
        click_function = "hit",
        function_owner = self,
        label          = "Hit",
        position       = {0, 0.5, 0},
        rotation       = {0, 180, 0},
        scale          = {0.8/Scale.x, 1, 0.8/Scale.z},
        width          = 700*Bound.size.x,
        height         = 700*Bound.size.z,
        color          = {0.6, 0.85, 0.6},
        font_color     = "Black",
        font_size      = 900*Bound.size.z
    })

    StayBtn.createButton({
        click_function = "stay",
        function_owner = self,
        label          = "Stay",
        position       = {0, 0.5, 0},
        rotation       = {0,180,0},
        scale          = {0.8/Scale.x, 1, 0.8/Scale.z},
        width          = 700*Bound.size.x,
        height         = 700*Bound.size.z,
        color          = {0.8, 0.8, 0.8},
        font_color     = "Black",
        font_size      = 900*Bound.size.z
    })
    for _,v in pairs(getObjects()) do
        if v.hasTag("score") then
            v.createButton({
                click_function = "bust",
                function_owner = self,
                label          = "Bust",
                position       = {10/Scale.x, 0, 0.8/Scale.z},
                rotation       = {0, 0, 0},
                scale          = {1.8/Scale.x, 1, 0.8/Scale.z},
                width          = 700*Bound.size.x,
                height         = 700*Bound.size.z,
                color          = {0.8, 0.6, 0.6},
                font_color     = "Black",
                font_size      = 900*Bound.size.z
            })
        end
    end

    scan2().shuffle()

    scriptzone ={}

    for _, v in pairs(getObjects()) do
        if v.type == "Scripting" then
            table.insert(scriptzone, v)
            v.createButton({
                click_function = "none",
                function_owner = self,
                label          = "0",
                position       = {0.4, 0.25, -1},
                rotation       = {0, 180, 0},
                scale          = {0.2, 0, 0.25},
                width          = 0,
                height         = 0,
                font_size      = 500,
                color          = "White",
                font_color     = "Grey",
            })

        end
    end
    
    -- Running countItems two times a second
    Wait.time(countItems, 0.5, -1)

    score = {}
    numberSum = {}
    plusSum = {}
    mult = {}
    countNumbercard = {}
    hasBeenPewd = false

    CreateScoreBoard()
end

function countItems()
    local hasDuplicateNumber = false

    for i = 1, 8 do
        score[i] = 0
        numberSum[i] = 0
        plusSum[i] = 0
        mult[i] = 1
        countNumbercard[i] = 0
    end

    for i, v in ipairs(scriptzone) do
		local seenNumbers = {}
        local scriptZoneObjects = v.getObjects() -- get objects already in the zone

        for _, scriptZoneObject in pairs(scriptZoneObjects) do -- key = 1|2|3|etc, object = actual TTS object
            if scriptZoneObject.hasTag("number") then
                local description = scriptZoneObject.getDescription() -- get the description
                local number = tonumber(description)  -- convert it to a number
                if(number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
					if not seenNumbers[number] then
						seenNumbers[number] = true
						numberSum[i] = numberSum[i] + number
					else
						hasDuplicateNumber = true
						if not hasBeenPewd then
                            local player = Player[v.getGMNotes()]
                            local broadcastMessage = ("%s got pewd!"):format(player.steam_name)
							broadcastToAll(broadcastMessage, player.color)
							hasBeenPewd = true
						end
					end
                end
                countNumbercard[i] = countNumbercard[i] + 1

            elseif scriptZoneObject.hasTag("plus") then
                local description = scriptZoneObject.getDescription() -- get the description
                local plus = tonumber(description)  -- convert it to a number
                plusSum[i] = plusSum[i] + plus

            elseif scriptZoneObject.hasTag("mult") then
                local description = scriptZoneObject.getDescription() -- get the description
                mult[i] = tonumber(description)  -- convert it to a number
            end
        end

        score[i] = numberSum[i]*mult[i]+plusSum[i]
        if countNumbercard[i] == 7 then
            score[i] = score[i] +15
        end

        v.editButton({label = score[i]})
    end
	
	if not hasDuplicateNumber then
		hasBeenPewd = false
	end

    UpdateScoreBoard()
end


function updateScore(zone)
    local scoreValue = getScore(zone)
    zone.editButton({
        index = 0,
        label = scoreValue,
    })
end

function getScore(zone)
    local score = 0
    local numberSum = 0
    local plusSum = 0
    local mult = 1
    local countNumbercard = 0
    local objects = zone.getObjects() -- get objects already in the zone

    for _, object in pairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("number") then
            local description = object.getDescription() -- get the description
            local number = tonumber(description)  -- convert it to a number
            if (number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
                 numberSum = numberSum + number
            end
            countNumbercard = countNumbercard +1

        end
    end

    for _, object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("plus") then
            local description = object.getDescription() -- get the description
            local plus = tonumber(description)  -- convert it to a number
            plusSum = plusSum + plus
        end
    end

    for _, object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("mult") then
            local description = object.getDescription() -- get the description
            mult = tonumber(description)  -- convert it to a number
        end
    end

    score = numberSum * mult + plusSum
    if countNumbercard == 7 then
        score = score + 15
    end

    return score
end

function bust(object, color, alt)
    for _, scriptZoneObject in pairs(scriptzone) do
        if scriptZoneObject.getGMNotes() == color then
            for _, v in pairs(scriptZoneObject.getObjects()) do
                if v.type == "Deck" or v.type == "Card" then
                    v.setPosition({2.06, 2.3, 1.07})
                    v.setRotation({0, 180, 0})
                end
            end
            break
        end
    end
end

function startgame()
	-- reset points
	for _, v in pairs(getObjects()) do
        if v.hasTag("score") then
            v.editInput({
                index = 0,
                value = 0,
            })
        end
    end

    -- put all cards back
    local drawDeck = scan2()
    for _, v in pairs(getObjects()) do
        if v ~= drawDeck and (v.type == "Deck" or v.type == "Card") then
            v.setPosition({-1.60, 2.3, 1.13})
            v.setRotation({0, 180, 180})
        end
    end

    drawDeck.shuffle()
end

function stay(object, color, alt)
    if alt then return false end
    if hasBeenPewd then return false end

    bust(_, color) -- Call bust function to reset player cards

    local Playerscore = 0
    for _, v in pairs(getObjects()) do
        if v.getGMNotes() == color then
           Playerscore = getScore(v)
        end
    end 

    for _, v in pairs(getObjects()) do
        if v.hasTag("score") and v.hasTag(color) then
            Score1 = v.getInputs()[1].value
            Score2 = Score1 + Playerscore
            v.editInput({
                index          = 0,
                value          = Score2,
            })
        end
    end
end

local lastHit = os.time()
function hit(object, color, alt)
    if alt then return false end
    if hasBeenPewd then return false end

    if os.time() - lastHit < 0.5 then return end
    lastHit = os.time()

    local handTransform = Player[color].getHandTransform()
    local angleY = math.rad(handTransform.rotation.y)
    local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
    local center = handTransform.position + forward * 14

    local spacingX = 3
    local offsetZ_up = 2
    local offsetZ_down = -2

    local emptyIndex = nil
    local filled = false

    -- 위쪽 3칸 (1 ~ 3)
    for i = -1, 1 do
        local localOffset = rotateOffset(spacingX * i, offsetZ_up, angleY)
        local origin = center + localOffset
        local hitList = Physics.cast({
            origin       = origin + Vector(0, -3, 0),
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })

        filled = false
        for _, v in pairs(hitList) do 
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                filled = true
                break
            end
        end

        if not filled then
            emptyIndex = (i + 2)  -- i = -1 → 1번칸, 0 → 2번칸, 1 → 3번칸
            emptyPos = origin + Vector(0, -3.3, 0)
            break
        end
    end

    -- 위쪽 3칸이 차면 아래쪽 첫 번째 칸에서 드로우 시작
    if not emptyIndex then
        for i = -2, 1 do
            local x = spacingX * i + spacingX / 2
            local localOffset = rotateOffset(x, offsetZ_down, angleY)
            local origin = center + localOffset
            local hitList2 = Physics.cast({
                origin       = origin + Vector(0, -3, 0),
                direction    = {0, -1, 0},
                type         = 3,
                size         = {1, 1, 1},
                orientation  = {0, 0, 0},
                max_distance = 3,
                debug        = false,
            })

            filled = false
            for _, v in ipairs(hitList2) do 
                if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                    filled = true
                    break
                end 
            end

            -- 비어있는 칸을 찾으면 emptyIndex를 설정
            if not filled then
                emptyIndex = (i + 5)  -- i = -2 → 3번 + 1 = 4, -1 → 5, 0 → 6, 1 → 7
                emptyPos = origin + Vector(0, -3.3, 0)
                break
            end
        end
    end

    for i = -2, 2 do  -- 5개 칸 (i = -2, -1, 0, 1, 2)
        local x = spacingX * i  -- x 값 조정: 좌우 간격 유지
        local localOffset = rotateOffset(x, offsetZ_down, angleY)
        local origin = handTransform.position + forward * 9 + localOffset
        local hitList3 = Physics.cast({
            origin       = origin + Vector(0, -3, 0),
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })

        filled2 = false
        for _, v in ipairs(hitList3) do 
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                filled2 = true
                break
            end
        end

        if not filled2 then
            emptyIndex2 = (i + 2)  -- i = -1 → 1번칸, 0 → 2번칸, 1 → 3번칸
            emptyPos2 = origin + Vector(0, -3.3, 0)
            break
        end
    end

    local drawcard = scan()
    if isempty then return end
    if drawcard.hasTag("special") then
        drawcard.setPositionSmooth(emptyPos2, false, false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    else
        drawcard.setPositionSmooth(emptyPos,false,false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    end

    isDeck = false
    local hitcheck = Physics.cast({
        origin       = {-1.60, 1.83, 1.13},
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 3,
        debug        = false,
    })

    for _, v in pairs(hitcheck) do 
        if v.hit_object.type == "Deck" then
            isDeck = true
        end
    end
    if isDeck == false then
        local hitcheck2 = Physics.cast({
            origin       = {2.06, 1.49, 1.07},
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            orientation  = {0, 0, 0},
            max_distance = 3,
            debug        = false,
        })
    
        for _, v in pairs(hitcheck2) do 
            if v.hit_object.type == "Deck" then
                v.hit_object.setPositionSmooth({-1.60, 2.3, 1.13}, false, true)
                v.hit_object.setRotation({0, 180, 180})
                v.hit_object.shuffle()
            end
        end
    end
end

-- Rotate Offset
function rotateOffset(x, z, Yangle)
    local rx = math.cos(-Yangle) * x - math.sin(-Yangle) * z
    local rz = math.sin(-Yangle) * x + math.cos(-Yangle) * z
    return Vector(rx, 0, rz)
end

function scan()
    isempty = true
    deckscan = Physics.cast({
        origin       = {-2, 2, 1},
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 1,
        debug        = false,
    })

    for _,v in ipairs(deckscan) do
        if v.hit_object.type == "Deck" then
            isempty = false

            return v.hit_object.takeObject()
        elseif v.hit_object.type == "Card" then
            isempty = false

            return v.hit_object
        end
    end
end

function scan2()
    local deckscan = Physics.cast({
        origin       = {-2, 2, 1},
        direction    = {0, -1, 0},
        type         = 3,
        size         = {1, 1, 1},
        orientation  = {0, 0, 0},
        max_distance = 1,
        debug        = false,
    })

    for _, v in pairs(deckscan) do
        if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
            return v.hit_object
        end
    end
end

function CreateScoreBoard()
    local xml = [[
    <Panel id="scoreHUD"
       width="260"
       height="30"

       anchorMin="1 0.5"
       anchorMax="1 0.5"
       rectAlignment="MiddleRight"

       offsetXY="-10 0"

       allowDragging="true"
       color="#000000AA"
       padding="1"
       autoLayout="Vertical">

        <Text id="scoreList" text="" fontSize="16" color="#FFFFFF" alignment="UpperLeft"/>
    </Panel>
    ]]
    UI.setXml(xml)
end

function getTotalScore(color)
    for _,v in ipairs(getObjects()) do
        if v.hasTag("score") and v.hasTag(color) then
            local inputs = v.getInputs()
            if inputs[1] then
                return tonumber(inputs[1].value) or 0
            end
        end
    end
    return 0
end

function UpdateScoreBoard()
    local txt = ""
   for i, color in ipairs(PLAYER_COLORS) do
        if Player[color].seated then 
        local roundScore = score[i] or 0
        local totalScore = getTotalScore(color)
        local playerName = Player[color].steam_name
        local newScore = totalScore + roundScore
        txt = ("%s%s: %d | %d (%d)\n"):format(txt, playerName, roundScore, totalScore, newScore)
       end
    end

    UI.setValue("scoreList", txt)
end