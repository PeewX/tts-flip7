-- CONSTS
local MSG_BUSTED = "%s got busted!"
local MSG_2ND_CHANCE = "Time for %s to use their second chance!"

-- ENUMS
PlayerStatus = {
    Default = 0,
    ActionRequired = 1,
    Stayed = 2,
    Busted = 3
}

SpecialCards = {
    SecondChance = "SecondChance"
}

DeckModes = {
    Base = 1,
    Vengeance = 2,
    Fusion = 3
}

-- Globals
PLAYER_COLORS = {"White", "Yellow", "Red", "Purple", "Green", "Pink", "Blue", "Orange"}
PlayerData = {}
NextPlayerStartToken = nil

-- Overwrite getSeatedPlayers to return the colors in correct order
local _getSeatedPlayers = getSeatedPlayers
function getSeatedPlayers()
    local sortedPlayers = {}
    for _, color in ipairs(PLAYER_COLORS) do
        if Player[color].seated then
            table.insert(sortedPlayers, color)
        end
    end

    return sortedPlayers
end

function onLoad()
    StartBtn = getObjectFromGUID("5324c0")
    HitBtn = getObjectFromGUID("e7358b")
    StayBtn = getObjectFromGUID("83c6d4")
    NewroundBtn = getObjectFromGUID("4c4180")
    Scale = StartBtn.getScale()
    Bound = StartBtn.getBoundsNormalized()

    StartBtn.createButton({
        click_function = "None",
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
        click_function = "StartGame",
        function_owner = self,
        label          = "Start Game",
        position       = {0, 0.5, -2/Scale.z},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = {0.6, 0.85, 0.6},
        font_color     = "Black",
        font_size      = 700
    })

    StartBtn.createButton({
        click_function  = "ModeSelUp",
        label           = "<",
        function_owner  = self,
        width           = 700,
        height          = 1000,
        position        = {-9.3/Scale.x, 0.5, 3/Scale.z},
        scale           = {1/Scale.x, 1, 1/Scale.z},
        font_size       = 549,
        color           = {0.9, 0.9, 0.9, 1},
    })

    StartBtn.createButton({
        click_function  = "ModeSelDown",
        label           = ">",
        function_owner  = self,
        width           = 700,
        height          = 1000,
        position        = {9.3/Scale.x, 0.5, 3/Scale.z},
        scale           = {1/Scale.x, 1, 1/Scale.z},
        font_size       = 549,
        color           = {0.9, 0.9, 0.9, 1},
    })

    StartBtn.createButton({
        click_function = "Brutal",
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

    for _, playerColor in pairs(PLAYER_COLORS) do
        local handTransform = Player[playerColor].getHandTransform()
        local angleY = math.rad(handTransform.rotation.y)
        local forward = Vector(math.sin(angleY), 0, math.cos(angleY))
        local center = handTransform.position + forward * 16

        PlayerData[playerColor] = {
            status = PlayerStatus.Default,
            scoreTile = getObjectsWithAllTags({"score", playerColor})[1],
            positionData = {
                handTransform = handTransform,
                angleY = angleY,
                forward = forward,
                center = center
            }
        }
    end

    -- create bust buttons and save scriptingZone to PlayerData
    for _, v in pairs(getObjects()) do
        if v.type == "Scripting" then
            v.createButton({
                click_function = "None",
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

    Score = {} -- could be moved to PlayerData?
    BaseGame = true
    IsBrutal = false -- only available in vengeance mode
    HasBeenPewd = false
    StartingPlayer = -1

    BaseBag = getObjectFromGUID("314599")
    ExpBag = getObjectFromGUID("ff1e2d")
    FusionBag = getObjectFromGUID("7eb9a5")
    StayBag = getObjectFromGUID("5e7ab9")
    BustedBag = getObjectFromGUID("5e7ab8")
    NextPlayerBag = getObjectFromGUID("5e7ab7")
    BaseBag.interactable = false
    ExpBag.interactable = false
    FusionBag.interactable = false
    StayBag.interactable = false
    BustedBag.interactable = false
    NextPlayerBag.interactable = false

    -- Init deck with base game
    DeckMode = DeckModes.Base
    Deck2 = Scan2()
    SetModeSelection()

    local hotKeyFunctions = {"Hit", "Stay", "Bust"}
    for _, func in pairs(hotKeyFunctions) do
        addHotkey(func, function(color, object, pos, keyUp) if keyUp and StartingPlayer > 0 then _G[func](object, color, false) end end, true)     
    end

    -- Running CountItems two times a second
    Wait.time(CountItems, 0.5, -1)
end

function None() end

function Brutal()
    if BaseGame then return end
    IsBrutal = not IsBrutal
    StartBtn.editButton({
        index = 4,
        label = ("Brutal Mode [%s]"):format(IsBrutal and "✓" or "")
    })
end

function StartGame()
    StartBtn.destruct()
    HitBtn.createButton({
        click_function = "Hit",
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
        click_function = "Stay",
        function_owner = self,
        label          = "Stay",
        position       = {0, 0.5, 0},
        rotation       = {0, 180, 0},
        scale          = {0.8/Scale.x, 1, 0.8/Scale.z},
        width          = 700*Bound.size.x,
        height         = 700*Bound.size.z,
        color          = {0.8, 0.8, 0.8},
        font_color     = "Black",
        font_size      = 900*Bound.size.z
    })

    for _, v in pairs(PlayerData) do
        v.scoreTile.createButton({
            click_function = "Bust",
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
        if IsBrutal then
            v.scoreTile.createButton({
                click_function = "Minus",
                function_owner = self,
                label          = "-15",
                position       = {8/Scale.x, 0, 3/Scale.z},
                rotation       = {0, 0, 0},
                scale          = {1.8/Scale.x, 1, 0.8/Scale.z},
                width          = 400*Bound.size.x,
                height         = 600*Bound.size.z,
                color          = {0.8, 0.6, 0.6},
                font_color     = "Black",
                font_size      = 900*Bound.size.z
            })
        end
    end

    NewroundBtn.createButton({
        click_function = "NewRoundCheck",
        function_owner = self,
        label          = "Next Round",
        position       = {0, -1.5, 0},
        rotation       = {0, 180, 0},
        scale          = {1/Scale.x, 1, 1/Scale.z},
        width          = 4000,
        height         = 1000,
        color          = {0, 0, 0.2, 0.9},
        font_color     = {0.8, 0.8, 0.8, 0.9},
        font_size      = 700,
        tooltip        = "Update scores, start next round"
    })

    NewroundBtn.createButton({
        click_function = "ResetGame",
        function_owner = self,
        label          = "New Game",
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

    ShiftStartingPlayer(true)
end

function ResetGame(_, color, _)
    if not Player[color].admin then
        broadcastToColor("You need to be promoted to use this feature", color)
        return
    end

    -- reset player specific data
	for _, v in pairs(PlayerData) do
        v.status = PlayerStatus.Default

        v.scoreTile.editInput({
            index = 0,
            value = 0,
        })
    end

    -- put all cards back
    local drawDeck = Scan2()
    for _, v in pairs(getObjects()) do
        if v ~= drawDeck and (v.type == "Deck" or v.type == "Card") then
            v.setPosition({-1.60, 2.3, 1.13})
            v.setRotation({0, 180, 180})
        end

        if v.hasTag("stay") then
            v.destruct()
        end
    end

    drawDeck.shuffle()
    ShiftStartingPlayer(true)
end

function ModeSelUp()
    DeckMode = DeckMode + 1
    if DeckMode > table.size(DeckModes) then DeckMode = 1 end
    SetModeSelection()
end

function ModeSelDown()
    DeckMode = DeckMode - 1
    if DeckMode < 1 then DeckMode = 3 end
    SetModeSelection()
end

function SetModeSelection()
    if DeckMode == 1 then
        BaseGame = true
        Deck2.destruct()
        Deck2 = BaseBag.takeObject()

        StartBtn.editButton({index=0, label="Flip 7"})
        StartBtn.editButton({index=4, label=""})
    elseif DeckMode == 2 then
        BaseGame = false
        Deck2.destruct()
        Deck2 = ExpBag.takeObject()

        StartBtn.editButton({index=0, label="Flip 7 With A Vengeance"})
        StartBtn.editButton({index=4, label="Brutal Mode [ ]"})
        
    elseif DeckMode == 3 then
        BaseGame = false
        Deck2.destruct()
        Deck2 = FusionBag.takeObject()

        StartBtn.editButton({index=0, label="Flip 7 Fusion Deck", tooltip="Base and Vengeance combined!"})
        StartBtn.editButton({index=4, label="Brutal Mode [ ]"})
    end

    IsBrutal = false

    Deck2.setPosition({-1.60, 2.1, 1.13})
    Deck2.setRotation({0, 180, 180})
    Deck2.shuffle()
end

function NewRoundCheck(object, color, alt)
    if alt then return end
    if AllPlayersDone() then return NewRound() end

    Player[color].showConfirmDialog("Not everyone is finished. Start next round anyway?", NewRound)
end

function NewRound()
    local posCount = 0.1
    Deck2 = Scan2()

    for _, v in pairs(getObjects()) do
        if v ~= Deck2 and (v.type == "Deck" or v.type == "Card") then
            v.setPosition({2.06, 1.49+posCount, 1.07})
            v.setRotation({0, 180, 0})
            posCount = posCount + 0.1
        end

        if v.hasTag("stay") then
            v.destruct()
        end
    end

    for _, color in pairs(PLAYER_COLORS) do
        local playerData = PlayerData[color]
        playerData.status = PlayerStatus.Default

        -- update score
        Score1 = playerData.scoreTile.getInputs()[1].value
        Score2 = Score1 + GetScore(playerData.scriptZone)
        playerData.scoreTile.editInput({
            index = 0,
            value = Score2,
        })
    end

    ShiftStartingPlayer()
end

function Minus(object, color, alt)
    Score1 = object.getInputs()[1].value
    Score2 = Score1 + -15

    if not IsBrutal and Score2 < 0 then
        Score2 = 0
    end

    object.editInput({
        index = 0,
        value = Score2,
    })
end

function CountItems()
    local hasDuplicateNumber = false
    local numberSum, plusSum, mult, countNumbercard = {}, {}, {}, {}
    for i = 1, 8 do
        Score[i] = 0
        numberSum[i] = 0
        plusSum[i] = 0
        mult[i] = 1
        countNumbercard[i] = 0
    end

    for i, color in ipairs(PLAYER_COLORS) do
        local v = PlayerData[color].scriptZone
		local seenNumbers = {}
        local scriptZoneObjects = v.getObjects() -- get objects already in the zone
        local hasSecondChance = nil
        local hasLuckyThirteen = false

        -- handle some special card flags before we iterate through all cards
        -- this is necessary to handle edge cases, e.g. player lost a special card during the round
        for _, scriptZoneObject in pairs(scriptZoneObjects) do
            -- second chance
            if scriptZoneObject.hasTag("special") and scriptZoneObject.getDescription() == SpecialCards.SecondChance then
                hasSecondChance = scriptZoneObject
            end

            -- lucky 13
            if scriptZoneObject.hasTag("thirteen") then
                hasLuckyThirteen = true
            end
        end

        for _, scriptZoneObject in pairs(scriptZoneObjects) do
            if scriptZoneObject.hasTag("number") and scriptZoneObject.is_face_down == false then
                local description = scriptZoneObject.getDescription()
                local number = tonumber(description)

                if number then
                    local seenNumberCount = seenNumbers[number] or 0
					if seenNumberCount == 0 or (number == 13 and seenNumberCount == 1 and hasLuckyThirteen) then
						seenNumbers[number] = seenNumberCount + 1
						numberSum[i] = numberSum[i] + number
					else
						hasDuplicateNumber = true
						if not HasBeenPewd then
                            local player = Player[color]
                            local broadcastMessage = (hasSecondChance and MSG_2ND_CHANCE or MSG_BUSTED):format(player.steam_name or player.color)
							broadcastToAll(broadcastMessage, player.color)
							if hasSecondChance then
                               player.pingTable(hasSecondChance.getPosition())
                            end
                            PlayerData[color].status = PlayerStatus.ActionRequired
							HasBeenPewd = true
						end
					end
                end

                countNumbercard[i] = countNumbercard[i] + 1

            elseif scriptZoneObject.hasTag("plus") and scriptZoneObject.is_face_down == false then
                local description = scriptZoneObject.getDescription()
                local plus = tonumber(description)
                plusSum[i] = plusSum[i] + plus

            elseif scriptZoneObject.hasTag("mult") and scriptZoneObject.is_face_down == false then
                local description = scriptZoneObject.getDescription()
                mult[i] = tonumber(description)

            elseif scriptZoneObject.hasTag("special") and scriptZoneObject.is_face_down == false then
                -- TODO: handle special cards
            end
        end

        if not hasDuplicateNumber and PlayerData[color].status == PlayerStatus.ActionRequired then
            PlayerData[color].status = PlayerStatus.Default
        end

        Score[i] = numberSum[i]*mult[i]+plusSum[i]
        if countNumbercard[i] == 7 then
            Score[i] = Score[i] + 15
        end

        -- only the special vengeance mode 0 card has the tag 'zero'
        for _, scriptZoneObject in ipairs(scriptZoneObjects) do
            if scriptZoneObject.hasTag("zero") and countNumbercard[i] < 7 then
                Score[i] = 0
            end
        end

        if IsBrutal == false and Score[i] < 0 then
            Score[i] = 0
        end

        PlayerData[color].cardCount = countNumbercard[i]
        v.editButton({label = Score[i]})
    end

	if not hasDuplicateNumber then
		HasBeenPewd = false
	end

    UpdateScoreBoard()
end

function GetScore(zone)
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
            if number then -- check if you actually get a number
                 numberSum = numberSum + number
            end
            countNumbercard = countNumbercard +1
        end

        if object.hasTag("plus") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
            local plus = tonumber(description)  -- convert it to a number
            plusSum = plusSum + plus
        end

        if object.hasTag("mult") and object.is_face_down == false then
            local description = object.getDescription() -- get the description
            mult = tonumber(description) or 0 -- convert it to a number
        end
    end

    score = math.floor(numberSum * mult + plusSum)
    if countNumbercard == 7 then
        score = score + 15
    end

    if not IsBrutal and score < 0 then
        score = 0
    end

    return score
end

function Bust(object, color, alt)
    if IsPlayerDoneWithRound(color) then
        broadcastToColor("Please wait until a new round has started", color)
        return false
    end

    for _, v in pairs(PlayerData[color].scriptZone.getObjects()) do
        if v.type == "Deck" or v.type == "Card" then
            v.flip()
        end
    end

    PlayerData[color].status = PlayerStatus.Busted

    -- add busted marker in player zone
    local player3DData = PlayerData[color].positionData
    local bustedToken = BustedBag.takeObject()
    if not bustedToken then return end
    bustedToken.setPosition(player3DData.center + RotateOffset(0, 6, player3DData.angleY))
    bustedToken.setRotation(Vector(0, player3DData.handTransform.rotation.y + 180, 0))
end

function Stay(object, color, alt)
    if alt then return false end
    if HasBeenPewd then return false end
    if IsPlayerDoneWithRound(color) then
        broadcastToColor("Please wait until a new round has started", color)
        return false
    end

    local playerData = PlayerData[color]

    playerData.status = PlayerStatus.Stayed

    -- add stay marker in player zone
    local player3DData = PlayerData[color].positionData
    local stayToken = StayBag.takeObject()
    if not stayToken then return end
    stayToken.setPosition(player3DData.center + RotateOffset(0, 6, player3DData.angleY))
    stayToken.setRotation(Vector(0, player3DData.handTransform.rotation.y + 180, 0))
end

local lastHit = os.time()
function Hit(object, color, alt)
    if alt then return false end
    if HasBeenPewd then return false end
    if IsPlayerDoneWithRound(color) then
        broadcastToColor("Please wait until a new round has started", color)
        return false
    end
    if PlayerData[color].cardCount >= 7 then return end

    if NextPlayerStartToken then
        NextPlayerStartToken.destruct()
        NextPlayerStartToken = nil
    end

    if os.time() - lastHit < 0.5 then return end
    lastHit = os.time()

    local player3DData = PlayerData[color].positionData
    local handTransform = player3DData.handTransform
    local angleY = player3DData.angleY
    local forward = player3DData.forward
    local center = player3DData.center

    local spacingX = 3
    local offsetZ_up = 2
    local offsetZ_down = -2

    local emptyIndex, emptyIndex2 = nil, nil
    local emptyPos, emptyPos2 = nil, nil
    local filled, filled2 = false, false

    -- 위쪽 3칸 (1 ~ 3)
    for i = -1, 1 do
        local localOffset = RotateOffset(spacingX * i, offsetZ_up, angleY)
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
            local localOffset = RotateOffset(x, offsetZ_down, angleY)
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
        local localOffset = RotateOffset(x, offsetZ_down, angleY)
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
        for _, v in pairs(hitList3) do
            if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
                filled2 = true
                break
            end
        end

        if not filled2 then
            emptyPos2 = origin + Vector(0, -3.3, 0)
            break
        end
    end

    local drawcard = Scan()
    if IsEmpty then
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
                drawcard = Scan()

                break
            end
        end

        -- IsEmpty will be updated in scan()
        if IsEmpty then return end
    end
    if not drawcard then return end

    if drawcard.hasTag("special") then
        drawcard.setPositionSmooth(emptyPos2, false, false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    else
        drawcard.setPositionSmooth(emptyPos,false,false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    end

    if drawcard.hasTag("seven") then
        ResetPlayerCards(color)
        local firstSlotOffset = RotateOffset(spacingX * -1, offsetZ_up, angleY)
        local firstSlotPos = center + firstSlotOffset + Vector(0, -3.3, 0)
        drawcard.setPositionSmooth(firstSlotPos, false, false)
        drawcard.setRotation(Vector(0, handTransform.rotation.y + 180, 0))
    end

    local isDeck = false
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
    if not isDeck then
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
function RotateOffset(x, z, Yangle)
    local rx = math.cos(-Yangle) * x - math.sin(-Yangle) * z
    local rz = math.sin(-Yangle) * x + math.cos(-Yangle) * z
    return Vector(rx, 0, rz)
end

function IsPlayerDoneWithRound(color)
    local playerStatus = PlayerData[color].status
    return playerStatus == PlayerStatus.Busted or playerStatus == PlayerStatus.Stayed
end

function ResetPlayerCards(color)
    for _, v in pairs(PlayerData[color].scriptZone.getObjects()) do
        if v.type == "Deck" or v.type == "Card" then
            v.setPosition({2.06, 2.3, 1.07})
            v.setRotation({0, 180, 0})
        end
    end
end

function AllPlayersDone()
    for color, data in pairs(PlayerData) do
        if Player[color].seated and data.status == 0 then
            return false
        end
    end
    
    return true
end

local castParams = {
    origin       = {-2, 2, 1},
    direction    = {0, -1, 0},
    type         = 3,
    size         = {1, 1, 1},
    orientation  = {0, 0, 0},
    max_distance = 1,
    debug        = false,
}

function Scan()
    local deckscan = Physics.cast(castParams)
    IsEmpty = true

    for _, v in ipairs(deckscan) do
        if v.hit_object.type == "Deck" then
            IsEmpty = false

            return v.hit_object.takeObject()
        elseif v.hit_object.type == "Card" then
            IsEmpty = false

            return v.hit_object
        end
    end
end

function Scan2()
    local deckscan = Physics.cast(castParams)

    for _, v in pairs(deckscan) do
        if v.hit_object.type == "Deck" or v.hit_object.type == "Card" then
            return v.hit_object
        end
    end
end

function GetTotalScore(color)
    local inputs = PlayerData[color].scoreTile.getInputs()
    if inputs[1] then
        return tonumber(inputs[1].value) or 0
    end
    return 0
end

function ShiftStartingPlayer(init)
    local seatedPlayers = getSeatedPlayers()
    if #seatedPlayers > 0 then
        StartingPlayer = init and math.random(1, #seatedPlayers) or (StartingPlayer + 1)
        if StartingPlayer > #seatedPlayers then
            StartingPlayer = 1
        end

        -- add begin marker in player zone
        local player3DData = PlayerData[seatedPlayers[StartingPlayer]].positionData
        NextPlayerStartToken = NextPlayerBag.takeObject()
        if not NextPlayerStartToken then return end
        NextPlayerStartToken.setPosition(player3DData.center + RotateOffset(0, 6, player3DData.angleY))
        NextPlayerStartToken.setRotation(Vector(0, player3DData.handTransform.rotation.y + 180, 0))

        local player = Player[seatedPlayers[StartingPlayer]]
        broadcastToAll(("%s begins.."):format(player.steam_name or player.color), player.color)
    end
end

function UpdateScoreBoard()
    local players = {}

    for i, color in ipairs(PLAYER_COLORS) do
        if Player[color].seated then
            local roundScore = Score[i] or 0
            local gameScore = GetTotalScore(color)
            local potentialScore = gameScore + roundScore

            local textColor = "#FFFFFF"
            if PlayerData[color].status == PlayerStatus.ActionRequired then
                textColor = "#FF8888"
            elseif potentialScore >= 200 then
                textColor = "#88CC88"
            elseif IsPlayerDoneWithRound(color) then
                textColor = "#AAAAAA"
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
                <Defaults>
                    <Text color="%s" />
                </Defaults>
                <Cell><Text text=" %s" alignment="MiddleLeft"/></Cell>
                <Cell><Text text="%d" /></Cell>
                <Cell><Text text="%d" /></Cell>
                <Cell><Text text="(%d)" /></Cell>
            </Row>
        ]], p.textColor, p.name, p.roundScore, p.gameScore, p.potentialScore)
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

                <Defaults>
                    <Cell dontUseTableCellBackground="true" />
                    <Panel color="#000000AA" />
                    <Text class="headerText" fontSize="16" fontStyle="Bold" color="#FFFFFF" />
                    <Text fontSize="14" alignment="MiddleCenter" />
                </Defaults>

                <Row>
                    <Cell><Panel><Text class="headerText" text=" Player" alignment="MiddleLeft"/></Panel></Cell>
                    <Cell><Panel><Text class="headerText" text="Round" /></Panel></Cell>
                    <Cell><Panel><Text class="headerText" text="Game" /></Panel></Cell>
                    <Cell><Panel><Text class="headerText" text="Total" /></Panel></Cell>
                </Row>

                %s
            </TableLayout>
    ]], 40 + (#players * 24), rows)

    UI.setXml(xml)
end

------ Utils

function table.size(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end