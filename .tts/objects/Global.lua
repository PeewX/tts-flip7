-- Globals
PLAYER_COLORS = {"Yellow", "Red", "White", "Orange", "Blue", "Pink", "Green", "Purple"}
PlayerData = {}

function onLoad()
    StartBtn = getObjectFromGUID("5324c0")
    HitBtn = getObjectFromGUID("e7358b")
    StayBtn = getObjectFromGUID("83c6d4")
    NewroundBtn = getObjectFromGUID("4c4180")
    Scale = StartBtn.getScale()
    Bound = StartBtn.getBoundsNormalized()

    StartBtn.createButton({
        click_function = "none",
        function_owner = self,
        label          = "Flip 7",
        position       = {0, 0.5, 3/Scale.z},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 8000,
        height         = 1000,
        color          = {0.9, 0.9, 0.9, 1},
        font_color     = "Black",
        font_size      = 700
    })

    StartBtn.createButton({
        click_function = "startgame",
        function_owner = self,
        label          = "Start Game",
        position       = {0, 0.5, -2/Scale.z},
        rotation       = {0,180,0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = {0.6, 0.85, 0.6},
        font_color     = "Black",
        font_size      = 700
    })

    StartBtn.createButton({
        click_function = "selection",
        label="<",
        function_owner = self,
        width = 700,
        height = 1000,
        position = {-9.3/Scale.x, 0.5, 3/Scale.z},
        scale = {1/Scale.x, 1, 1/Scale.z},
        font_size = 549,
        color = {0.9, 0.9, 0.9, 1},
    })
    StartBtn.createButton({
        click_function = "selection",
        label=">",
        function_owner = self,
        width = 700,
        height = 1000,
        position = {9.3/Scale.x, 0.5, 3/Scale.z},
        scale = {1/Scale.x, 1, 1/Scale.z},
        font_size = 549,
        color = {0.9, 0.9, 0.9, 1},
    })

    StartBtn.createButton({
        click_function = "brutal",
        function_owner = self,
        label          = "",
        position       = {0, 0.5, 0.5/Scale.z},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 6000,
        height         = 1000,
        color          = {0, 0, 0, 0},
        font_color     = {1, 1, 1, 100},
        font_size      = 700
    })

    for _, v in pairs(PLAYER_COLORS) do
        PlayerData[v] = {}
    end

    scriptzone = {}
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
            PlayerData[v.getGMNotes()].scriptZone = v
        end
    end

    score = {}
    numberSum = {}
    plusSum = {}
    mult = {}
    countNumbercard = {}
    isbase = true
    isbrutal = false
    hasBeenPewd = false

    baseBag = getObjectFromGUID("314599")
    expBag = getObjectFromGUID("ff1e2d")
    stayBag = getObjectFromGUID("5e7ab9")
    baseBag.interactable = false
    expBag.interactable = false
    stayBag.interactable = false

    -- Init deck with base game
    deck2 = scan2()
    deck2.destruct()
    deck2 = baseBag.takeObject()
    deck2.setPosition({-1.60, 2.1, 1.13})
    deck2.setRotation({0, 180, 180})
    deck2.shuffle()

    -- Running countItems two times a second
    Wait.time(countItems, 0.5, -1)
end

function none()
end

function brutal()
    if isbrutal then
        isbrutal = false
        StartBtn.editButton({index=4,label="Brutal Mode [ ]"})
    else
        isbrutal = true
        StartBtn.editButton({index=4,label="Brutal Mode [✓]"})
    end
end

function startgame()
    StartBtn.destruct()
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
                position       = {0, 0, 3/Scale.z},
                rotation       = {0, 0, 0},
                scale          = {1.8/Scale.x, 1, 0.8/Scale.z},
                width          = 650*Bound.size.x,
                height         = 600*Bound.size.z,
                color          = {0.8, 0.6, 0.6},
                font_color     = "Black",
                font_size      = 900*Bound.size.z
            })
            if isbrutal then
                v.createButton({
                    click_function = "minus",
                    function_owner = self,
                    label          = "-15",
                    position       = {8/Scale.x,0,3/Scale.z},
                    rotation       = {0,0,0},
                    scale          = {1.8/Scale.x,1,0.8/Scale.z},
                    width          = 400*Bound.size.x,
                    height         = 600*Bound.size.z,
                    color          = {0.8,0.6,0.6},
                    font_color     = "Black",
                    font_size      = 900*Bound.size.z
                })
            end
        end

    end

    if isbase == false then
        NewroundBtn.createButton({
            click_function = "newround",
            function_owner = self,
            label          = "New Round",
            position       = {0, 0.5, 0},
            rotation       = {0, 180, 0},
            scale          = {1/Scale.x, 1, 1/Scale.z},
            width          = 4000,
            height         = 1000,
            color          = "White",
            font_color     = "Black",
            font_size      = 700,
            tooltip        = "Calculate the scores and start the next round."
        })
    else
        NewroundBtn.createButton({
            click_function = "newround",
            function_owner = self,
            label          = "New Round",
            position       = {0, 0.5, 0},
            rotation       = {0, 180, 0},
            scale          = {1/Scale.x, 1, 1/Scale.z},
            width          = 4000,
            height         = 1000,
            color          = "White",
            font_color     = "Black",
            font_size      = 700,
            tooltip        = "Calculate the scores and start the next round."
        })
    end

    NewroundBtn.createButton({
        click_function = "resetGame",
        function_owner = self,
        label          = "Reset Game",
        position       = {-7, -2, -23.25},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = "White",
        font_color     = "Black",
        font_size      = 700,
        tooltip        = "Reset all player points and cards"
    })
end

function resetGame(_, color, _)
    if not (Player[color].host or Player[color].promoted) then return end

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

function selection()
    if isbase then
        isbase = false
        isbrutal = false
        deck2.destruct()
        deck2 = expBag.takeObject()
        deck2.setPosition({-1.60, 2.1, 1.13})
        deck2.setRotation({0,180,180})
        deck2.shuffle()

        StartBtn.editButton({index=0,label="Flip 7 With A Vengeance"})
        StartBtn.editButton({index=4,label="Brutal Mode [ ]"})

    else
        isbase = true
        isbrutal = false
        deck2.destruct()
        deck2 = baseBag.takeObject()
        deck2.setPosition({-1.60, 2.1, 1.13})
        deck2.setRotation({0,180,180})
        deck2.shuffle()

        StartBtn.editButton({index=0,label="Flip 7"})
        StartBtn.editButton({index=4,label=""})

    end
end


function newround()
     deck2 = scan2()
     posCount = 0.1
    for i,v in ipairs(getObjects()) do
        if v ~= deck2 and (v.type=="Deck" or v.type=="Card") then
            v.setPosition({2.06, 1.49+posCount, 1.07})
            v.setRotation({0,180,0})
            posCount = posCount + 0.1
        end
    end

    for i,v in ipairs(getObjects()) do
        if v.hasTag("stay") then
            v.destruct()
        end
    end
    for _,c in ipairs(PLAYER_COLORS) do
        for i,v in ipairs(getObjects()) do
            if v.getGMNotes() == c then
            Playerscore = getScore(v)
            end
        end
        for i,v in ipairs(getObjects()) do
            if v.hasTag("score") and v.hasTag(c) then
                Score1 = v.getInputs()[1].value
                Score2 = Score1 + Playerscore
                v.editInput({
                    index          = 0,
                    value          = Score2,
                })
            end
        end
    end
end

function minus(o,p,c)
    Score1 = o.getInputs()[1].value
    Score2 = Score1 + -15
    if isbrutal == false then
        if Score2 < 0 then
            Score2 = 0
        end
    end
    o.editInput({
        index          = 0,
        value          = Score2,
    })
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
        local color = v.getGMNotes()

        for _, scriptZoneObject in pairs(scriptZoneObjects) do -- key = 1|2|3|etc, object = actual TTS object
            if scriptZoneObject.hasTag("number") and scriptZoneObject.is_face_down == false then
                local description = scriptZoneObject.getDescription() -- get the description
                local number = tonumber(description)  -- convert it to a number
                if(number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
					if not seenNumbers[number] then
						seenNumbers[number] = true
						numberSum[i] = numberSum[i] + number
					else
						hasDuplicateNumber = true
						if not hasBeenPewd then
                            local player = Player[color]
                            local broadcastMessage = ("%s got pewd!"):format(player.steam_name or player.color)
							broadcastToAll(broadcastMessage, player.color)
                            PlayerData[color].state = "Pewd"
							hasBeenPewd = true
						end
					end
                end
                countNumbercard[i] = countNumbercard[i] + 1

            elseif scriptZoneObject.hasTag("plus") and scriptZoneObject.is_face_down == false then
                local description = scriptZoneObject.getDescription() -- get the description
                local plus = tonumber(description)  -- convert it to a number
                plusSum[i] = plusSum[i] + plus

            elseif scriptZoneObject.hasTag("mult") and scriptZoneObject.is_face_down == false then
                local description = scriptZoneObject.getDescription() -- get the description
                mult[i] = tonumber(description)  -- convert it to a number

            elseif scriptZoneObject.hasTag("special") and scriptZoneObject.is_face_down == false then
                
            end
        end

        if not hasDuplicateNumber and PlayerData[color].state == "Pewd" then
            PlayerData[color].state = ""
        end

        score[i] = numberSum[i]*mult[i]+plusSum[i]
        if countNumbercard[i] == 7 then
            score[i] = score[i] +15
        end

        -- is this correct? Should only apply to brutal rules
        for _, scriptZoneObject in ipairs(scriptZoneObjects) do
            if scriptZoneObject.hasTag("zero") and countNumbercard[i] < 7 then
                score[i] = 0
            end
        end

        if isbrutal == false then
            if score[i] < 0 then
                score[i] = 0
            end
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
        if object.hasTag("number") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
            local number = tonumber(description)  -- convert it to a number
            if (number ~= nil) then -- check if you actually get a number (tonumber returns nil if it isn't)
                 numberSum = numberSum + number
            end
            countNumbercard = countNumbercard +1

        end
    end

    for _, object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("plus") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
            local plus = tonumber(description)  -- convert it to a number
            plusSum = plusSum + plus
        end
    end

    for _, object in ipairs(objects) do -- key = 1|2|3|etc, object = actual TTS object
        if object.hasTag("mult") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
            mult = tonumber(description) or 0 -- convert it to a number
        end
    end

    score = math.floor(numberSum * mult + plusSum)
    if countNumbercard == 7 then
        score = score + 15
    end

    if isbrutal == false then
        if score < 0 then
            score = 0
        end
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

function stay(object, color, alt)
    if alt then return false end
    if isbase and hasBeenPewd then return false end
    --^ quick workaround for vengeance mode until its fully implemented, since you can draw and stay with a lucky 13

    if isbase then
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
    else
        -- 플레이어 기준 위치 및 회전
        local handTransform = Player[color].getHandTransform()
        -- 회전 각도 (플레이어 기준 정방향)
        local angleY = math.rad(handTransform.rotation.y)
        local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
        local center = handTransform.position + forward * 16

        local spacingX = 3
        local offsetZ_up = 2
        local offsetZ_down = -2

        stayToken = stayBag.takeObject()
        stayToken.setPosition(center + rotateOffset(0, 6, angleY))
        stayToken.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    end
end

local lastHit = os.time()
function hit(object, color, alt)
    if alt then return false end
    if isbase and hasBeenPewd then return false end
    --^ quick workaround for vengeance mode until its fully implemented, since you can draw and stay with a lucky 13

    if os.time() - lastHit < 0.5 then return end
    lastHit = os.time()

    local handTransform = Player[color].getHandTransform()
    local angleY = math.rad(handTransform.rotation.y)
    local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
    local center = handTransform.position + forward * 16

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
        local origin = handTransform.position + forward * 11 + localOffset
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
    if isempty then
        local discardCheck = Physics.cast({
            origin       = {2.06, 1.49, 1.07},
            direction    = {0, -1, 0},
            type         = 3,
            size         = {1, 1, 1},
            max_distance = 3,
        })

        for _, v in ipairs(discardCheck) do
            if v.hit_object.type == "Deck" then
                local discardDeck = v.hit_object

                -- draw pile 위치로 이동
                discardDeck.setPositionSmooth({-1.60, 2.3, 1.13}, false, true)
                discardDeck.setRotation({0, 180, 180})
                discardDeck.shuffle()
                -- 다시 scan
                drawcard = scan()

                break
            end
        end

        -- isempty will be updated in scan()
        if isempty then return end
    end

    if drawcard.hasTag("special") then
        drawcard.setPositionSmooth(emptyPos2, false, false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    else
        drawcard.setPositionSmooth(emptyPos,false,false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    end

    if drawcard.hasTag("seven") then
        bust(object, color, alt)
        local firstSlotOffset = rotateOffset(spacingX * -1, offsetZ_up)
        local firstSlotPos = center + firstSlotOffset + Vector(0, -3.3, 0)
        drawcard.setPositionSmooth(firstSlotPos, false, false)
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

function GetTotalScore(color)
    for _, v in pairs(getObjects()) do
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
    local players = {}

    for i, color in ipairs(PLAYER_COLORS) do
        if Player[color].seated then
            local roundScore = score[i] or 0
            local gameScore = GetTotalScore(color)
            local potentialScore = gameScore + roundScore

            local textColor = "#FFFFFF"
            if PlayerData[color].state == "Pewd" then
                textColor = "#FF8888"
            end

            table.insert(players, {
                name = Player[color].steam_name,
                roundScore = roundScore,
                gameScore = gameScore,
                potentialScore = potentialScore,
                textColor = textColor
            })
        end
    end

    table.sort(players, function(a, b)
        return a.potentialScore > b.potentialScore
    end)

    local rows = ""

    for _, p in ipairs(players) do
        rows = rows .. string.format([[
            <Row>
                <Cell dontUseTableCellBackground="true"><Text text=" %s" fontSize="15" color="%s" alignment="MiddleLeft"/></Cell>
                <Cell dontUseTableCellBackground="true"><Text text="%d" fontSize="15" color="%s" alignment="MiddleCenter"/></Cell>
                <Cell dontUseTableCellBackground="true"><Text text="%d" fontSize="15" color="%s" alignment="MiddleCenter"/></Cell>
                <Cell dontUseTableCellBackground="true"><Text text="(%d)" fontSize="15" color="%s" alignment="MiddleCenter"/></Cell>
            </Row>
        ]], p.name, p.textColor, p.roundScore, p.textColor, p.gameScore, p.textColor, p.potentialScore, p.textColor)
    end

    local xml = string.format([[
    <TableLayout columnWidths="120 60 60 60"
            width="300"
            height="%d"
            anchorMin="1 0.5"
            anchorMax="1 0.5"
            rectAlignment="MiddleRight"
            offsetXY="-10 0"
            allowDragging="true"
            returnToOriginalPositionWhenReleased="false"
            color="#000000AA"
            cellPadding ="0">

                <Row fontStyle="Bold">
                    <Cell dontUseTableCellBackground="true"><Panel color="#000000AA"><Text text=" Player" fontSize="16" fontStyle="Bold" color="#FFFFFF" alignment="MiddleLeft"/></Panel></Cell>
                    <Cell dontUseTableCellBackground="true"><Panel color="#000000AA"><Text text="Round" fontSize="16" fontStyle="Bold" color="#FFFFFF" alignment="MiddleCenter"/></Panel></Cell>
                    <Cell dontUseTableCellBackground="true"><Panel color="#000000AA"><Text text="Game" fontSize="16" fontStyle="Bold" color="#FFFFFF" alignment="MiddleCenter"/></Panel></Cell>
                    <Cell dontUseTableCellBackground="true"><Panel color="#000000AA"><Text text="Total" fontSize="16" fontStyle="Bold" color="#FFFFFF" alignment="MiddleCenter"/></Panel></Cell>
                </Row>
                %s
            </TableLayout>
    ]], 40 + (#players * 24), rows)

    UI.setXml(xml)
end