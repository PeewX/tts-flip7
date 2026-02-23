-- CONSTS
local MSG_BUSTED = "%s got busted!"
local MSG_2ND_CHANCE = "Time for %s to use their second chance!"
local BUSTED_CARD_HIGHLIGHT_DURATION = 3

DECK_INFO = {
    {Name = "Flip 7", ShortName = "Flip 7", Tooltip = "", Brutal = false},
    {Name = "Flip 7 With A Vengeance", ShortName = "Flip 7 Vengeance", Tooltip = "", Brutal = true},
    {Name = "Flip 7 Fusion Deck", ShortName = "Flip 7 Fusion ", Tooltip = "Base and Vengeance combined!", Brutal = true},
}

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
GameStarted = false

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

function IsSnapPointOccupied(snapPoint)
    local snapPos = snapPoint.position

    -- get objects near the snap point
    local nearby = UsePhysicsCast({
        origin       = snapPos,
        direction    = {0, 1, 0},
        max_distance = 0
    })

    for _, v in pairs(nearby) do
        if v.hit_object ~= nil and (v.hit_object.type == "Deck" or v.hit_object.type == "Card") then
            return true
        end
    end

    return false
end

function onLoad()
    InitPlayerData()
    InitButtonsAndObjects()

    Score = {} -- could be moved to PlayerData?
    IsBrutal = false -- only available in vengeance mode
    HasBeenPewd = false
    StartingPlayer = -1

    -- Init deck with base game
    DeckMode = DeckModes.Base
    --Deck2 = Scan2()
    SetModeSelection()

    local hotKeyFunctions = {"Hit", "Stay", "Bust"}
    for _, func in pairs(hotKeyFunctions) do
        addHotkey(func, function(color, object, pos, keyUp) if keyUp and StartingPlayer > 0 then _G[func](object, color, false) end end, true)
    end

    -- Running CountItems two times a second
    Wait.time(CountItems, 0.5, -1)
end

function InitPlayerData()
    -- Sort snap points row-by-row (center → player, left → right)
    local function sortSnapPointsForPlayer(snapPointTable, center, forward)
        -- Right vector (perpendicular to forward)
        local right = Vector(forward.z, 0, -forward.x)

        for _, sp in ipairs(snapPointTable) do
            local offset = sp.position - center
            sp._depth = offset:dot(forward) -- depth to center
            sp._horizontal = offset:dot(right)
        end

        -- 1) Rows: closest to center first
        -- 2) Inside row: left to right
        table.sort(snapPointTable, function(a, b)
            if math.abs(a._depth - b._depth) > 0.1 then
                return a._depth > b._depth
            end
            return a._horizontal < b._horizontal
        end)

        for _, sp in pairs(snapPointTable) do
            sp._depth = nil
            sp._horizontal = nil
        end
    end

    local snapPoints = Global.getSnapPoints()
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
            },
            snapPoints = {
                numbers = {},
                special = {}
            }
        }

        local snapPointsNumbers = PlayerData[playerColor].snapPoints.numbers
        local snapPointsSpecial = PlayerData[playerColor].snapPoints.special

        for _, snapPoint in pairs(snapPoints) do
            local tagSet = {}
            for _, tag in pairs(snapPoint.tags) do
                tagSet[tag] = true
            end


            if tagSet[playerColor] then
                if tagSet["number"] then
                    table.insert(snapPointsNumbers, snapPoint)
                end
                if tagSet["Special"] then
                    table.insert(snapPointsSpecial, snapPoint)
                end
            end
        end

        sortSnapPointsForPlayer(snapPointsNumbers, center, forward)
        sortSnapPointsForPlayer(snapPointsSpecial, center, forward)
    end

    -- save scriptingZone to PlayerData
    for _, v in pairs(getObjects()) do
        if v.type == "Scripting" then
            PlayerData[v.getGMNotes()].scriptZone = v
        end
    end
end

function InitButtonsAndObjects()
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

    for _, color in pairs(PlayerData) do
        color.scriptZone.createButton({
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
    end

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
end

function None() end

function Brutal()
    if not DECK_INFO[DeckMode].Brutal then return end
    IsBrutal = not IsBrutal
    StartBtn.editButton({index = 4, label = ("Brutal Mode [%s]"):format(IsBrutal and "✓" or " ")})
    UI.setAttribute("state", "text", ("%s%s"):format(DECK_INFO[DeckMode].Name, IsBrutal and " (Brutal)" or ""))
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
                click_function = "SetBrutalModeEndScore",
                function_owner = self,
                label          = "",
                position       = {8/Scale.x, 0, 3/Scale.z},
                rotation       = {0, 0, 0},
                scale          = {1.8/Scale.x, 1, 0.8/Scale.z},
                width          = 400*Bound.size.x,
                height         = 600*Bound.size.z,
                color          = {0, 0, 0, 0},
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

    GameStarted = true
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

        v.scoreTile.editInput({index = 0, value = 0})
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
    if Deck2 then Deck2.destruct() end

    if DeckMode == DeckModes.Base then
        Deck2 = BaseBag.takeObject()
    elseif DeckMode == DeckModes.Vengeance then
        Deck2 = ExpBag.takeObject()
    elseif DeckMode == DeckModes.Fusion then
        Deck2 = FusionBag.takeObject()
    end

    IsBrutal = false

    StartBtn.editButton({index = 0, label = DECK_INFO[DeckMode].Name, tooltip = DECK_INFO[DeckMode].Tooltip})
    StartBtn.editButton({index = 4, label = DECK_INFO[DeckMode].Brutal and "Brutal Mode [ ]" or ""})
    UI.setAttribute("state", "text", ("%s%s"):format(DECK_INFO[DeckMode].Name, IsBrutal and " (Brutal)" or ""))

    Deck2.setPosition({-1.60, 2.1, 1.13})
    Deck2.setRotation({0, 180, 180})
    Deck2.shuffle()
end

function NewRoundCheck(object, color, alt)
    if alt then return end
    if AllPlayersDone() then return NewRound() end

    Player[color].showConfirmDialog("Not everyone has finished. Start the next round anyway?", NewRound)
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
        local currentScore = playerData.scoreTile.getInputs()[1].value
        playerData.scoreTile.editInput({index = 0, value = currentScore + GetScore(playerData.scriptZone)})
    end

    ShiftStartingPlayer()
end

function SetBrutalModeEndScore(object, color, alt)
    if not IsBrutal then return end

    local currentScore = object.getInputs()[1].value
    local modifierValue = object.hasTag(color) and 15 or -15

    object.editInput({index = 0, value = currentScore + modifierValue})
end

function CountItems()
    if not GameStarted then return end

    local hasDuplicateNumber = false
    local numberSum, plusSum, mult, countNumbercard = {}, {}, {}, {}
    for i = 1, 8 do
        Score[i] = 0
        numberSum[i] = 0
        plusSum[i] = 0
        mult[i] = 1
        countNumbercard[i] = 0
    end

    if IsBrutal then
        for _, color in ipairs(PLAYER_COLORS) do
            PlayerData[color].scoreTile.editButton({
                index = 1,
                label = "",
                color = {0, 0, 0, 0}
            })
        end
    end

    for i, color in ipairs(PLAYER_COLORS) do
        local scriptZone = PlayerData[color].scriptZone
        local scriptZoneObjects = scriptZone.getObjects() -- get objects already in the zone
		local seenNumbers = {}
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
                    local seenNumberCount = 0
                    local seenNumberTableData = seenNumbers[number]
                    if seenNumberTableData then
                        seenNumberCount = seenNumberTableData.count
                    end

					if seenNumberCount == 0 or (number == 13 and seenNumberCount == 1 and hasLuckyThirteen) then
                        numberSum[i] = numberSum[i] + number

                        if not seenNumbers[number] then
                            seenNumbers[number] = {}
                        end

						seenNumbers[number].count = seenNumberCount + 1
                        -- save the seen object, except for the lucky 13
                        if not scriptZoneObject.hasTag("thirteen") then
                            seenNumbers[number].obj = scriptZoneObject
                        end
					else
						hasDuplicateNumber = true
						if not HasBeenPewd then
                            local player = Player[color]
                            local broadcastMessage = (hasSecondChance and MSG_2ND_CHANCE or MSG_BUSTED):format(player.steam_name or color)
							broadcastToAll(broadcastMessage, color)
                            PlayerData[color].status = PlayerStatus.ActionRequired
							HasBeenPewd = true

                            -- visual notifications
                            scriptZoneObject.highlightOn("Red", BUSTED_CARD_HIGHLIGHT_DURATION)
                            seenNumberTableData.obj.highlightOn("Red", BUSTED_CARD_HIGHLIGHT_DURATION)
							if hasSecondChance then
                               player.pingTable(hasSecondChance.getPosition())
                               hasSecondChance.highlightOn("White", BUSTED_CARD_HIGHLIGHT_DURATION)
                            end
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

        if countNumbercard[i] == 7 and not HasBeenPewd then
            if IsBrutal then
                for _, brutalPlayerColor in pairs(PLAYER_COLORS) do
                    local buttonLabel = brutalPlayerColor == color and "+15" or "-15"
                    local buttonColor = brutalPlayerColor == color and {0.6, 0.8, 0.6} or {0.8, 0.6, 0.6}

                    PlayerData[brutalPlayerColor].scoreTile.editButton({
                        index = 1,
                        label = buttonLabel,
                        color = buttonColor
                    })
                end
            else
                Score[i] = Score[i] + 15
            end
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
        scriptZone.editButton({index = 0, label = Score[i]})
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
    local objects = zone.getObjects()

    for _, object in pairs(objects) do
        if object.hasTag("number") and object.is_face_down == false then
            local description = object.getDescription()
            local number = tonumber(description)
            if number then numberSum = numberSum + number end
            countNumbercard = countNumbercard + 1
        end

        if object.hasTag("plus") and object.is_face_down == false then
            local description = object.getDescription()
            local plus = tonumber(description)
            plusSum = plusSum + plus
        end

        if object.hasTag("mult") and object.is_face_down == false then
            local description = object.getDescription()
            mult = tonumber(description) or 0
        end
    end

    score = math.floor(numberSum * mult + plusSum)
    if countNumbercard == 7 and not IsBrutal then
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
    local playerData = PlayerData[color]
    if playerData.cardCount >= 7 then return end

    if NextPlayerStartToken then
        NextPlayerStartToken.destruct()
        NextPlayerStartToken = nil
    end

    if os.time() - lastHit < 0.5 then return end
    lastHit = os.time()

    local drawcard = Scan()
    if drawcard == nil then return end

    if drawcard.hasTag("seven") then
        ResetPlayerCards(color)
    end

    local targetSnapPoints
    if drawcard.hasTag("number") then
        targetSnapPoints = playerData.snapPoints.numbers
    elseif drawcard.hasTag("special") then
        targetSnapPoints = playerData.snapPoints.special
    end

    if targetSnapPoints then
        local foundSpaceForCard = false
        for _, point in ipairs(targetSnapPoints) do
            if not IsSnapPointOccupied(point) then
                drawcard.setPositionSmooth(point.position, false, false)
                drawcard.setRotation(Vector(0, playerData.positionData.handTransform.rotation.y + 180, 0))
                foundSpaceForCard = true
                break
            end
        end

        -- if no more space, just deal to the players hand
        if not foundSpaceForCard then
            drawcard.deal(1, color)
        end
    end

    -- reshuffle draw deck if empty
    local drawPileHasCards = false
    local objectsNearDrawPile = UsePhysicsCast({
        origin       = {-1.60, 1.83, 1.13},
        max_distance = 3,
    })

    for _, v in pairs(objectsNearDrawPile) do
        if v.hit_object.type == "Deck" then
            drawPileHasCards = true
        end
    end
    if not drawPileHasCards then
        local objectsNearDiscardPile = UsePhysicsCast({
            origin       = {2.06, 1.49, 1.07},
            max_distance = 3
        })

        for _, v in pairs(objectsNearDiscardPile) do
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

function Scan()
    local deckscan = UsePhysicsCast({origin = {-2, 2, 1}})
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
    local deckscan = UsePhysicsCast({origin = {-2, 2, 1}})

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
    local activePlayers = {}
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

            table.insert(activePlayers, {
                name = {text = " " .. Player[color].steam_name, color = textColor},
                round = {text = roundScore, color = textColor},
                game = {text = gameScore, color = textColor},
                total = {text = potentialScore, color = textColor}
            })
        end
    end

    table.sort(activePlayers, function(a, b) return a.total.text > b.total.text end)

    UI.setAttribute("table", "height", 40 + (#activePlayers * 24))
    for i, player in ipairs(activePlayers) do
        UI.setAttribute(("player%d"):format(i), "active", "true")
        UI.setAttributes(("player%d-name"):format(i), player.name)
        UI.setAttributes(("player%d-round"):format(i), player.round)
        UI.setAttributes(("player%d-game"):format(i), player.game)
        UI.setAttributes(("player%d-total"):format(i), player.total)
    end

    -- hide all rows without an active player
    for i = #activePlayers + 1, #PLAYER_COLORS do
        UI.setAttribute(("player%d"):format(i), "active", "false")
    end
end

------ TTS specific utils
function UsePhysicsCast(customCastParams)
    return Physics.cast({
        origin       = customCastParams.origin       or {0, 0, 0},
        direction    = customCastParams.direction    or {0, -1, 0},
        type         = customCastParams.type         or 3,
        size         = customCastParams.size         or {1, 1, 1},
        orientation  = customCastParams.orientation  or {0, 0, 0},
        max_distance = customCastParams.max_distance or 1,
        debug        = customCastParams.debug        or false,
    })
end

------ Utils
function table.size(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end