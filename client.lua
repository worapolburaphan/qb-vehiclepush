local QBCore = exports['qb-core']:GetCoreObject()

Config = {} 
Config.DamageNeeded = 900 -- 100.0 being broken and 1000.0 being fixed a lower value than 100.0 will break it
Config.MaxWidth = 5.0 -- Will complete soon
Config.MaxHeight = 5.0
Config.MaxLength = 5.0
Config.PushMaxSpeed = 0.7

local Keys = {
  ["E"] = 38, ["A"] = 34, ["D"] = 9, ["W"] = 32, ["LEFTSHIFT"] = 21, ["ESC"] = 200, ["LOOK_LR"] = 1, ["LOOK_UD"] = 2
}

local First = vector3(0.0, 0.0, 0.0)
local Second = vector3(5.0, 5.0, 5.0)

local Vehicle = {Coords = nil, Vehicle = nil, Dimension = nil, IsInFront = false, Distance = nil, Pushable = false}

Citizen.CreateThread(function()
    Citizen.Wait(200)
    while true do
        local ped = PlayerPedId()
        local closestVehicle, Distance = QBCore.Functions.GetClosestVehicle()
        local vehicleCoords = GetEntityCoords(closestVehicle)
        local vehicleForwardVector =  GetEntityForwardVector(closestVehicle)
        local dimension = GetModelDimensions(GetEntityModel(closestVehicle), First, Second)
        if Distance < 6.0 and (DoesEntityExist(closestVehicle) and IsEntityAVehicle(closestVehicle)) and not IsPedInAnyVehicle(ped, false) and IsVehicleSeatFree(Vehicle.Vehicle, -1) then
            Vehicle.Coords = vehicleCoords
            Vehicle.Dimensions = dimension
            Vehicle.Vehicle = closestVehicle
            Vehicle.Distance = Distance
            Vehicle.IsInFront = GetDistanceBetweenCoords(vehicleCoords + vehicleForwardVector, GetEntityCoords(ped), true) < GetDistanceBetweenCoords(vehicleCoords + vehicleForwardVector * -1, GetEntityCoords(ped), true)
        else
            Vehicle = {Coords = nil, Vehicle = nil, Dimensions = nil, IsInFront = false, Distance = nil, Pushable = false}
        end
        Citizen.Wait(500)
    end
end)

local dict, anim = 'missfinale_c2ig_11', 'pushcar_offcliff_m'

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        local ped = PlayerPedId()
        if Vehicle.Pushable then
            -- trigger anim
            SetEntityAnimCurrentTime(ped, dict, anim, 1.0)
            if IsDisabledControlPressed(0, Keys["W"]) then
                StopAnimTask(ped, dict, anim, 0.0)
                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do
                    Citizen.Wait(2)
                end
                TaskPlayAnim(ped, dict, anim, 2.0, -8.0, -1, 35, 0, 0, 0, 0)
                while true do
                    Citizen.Wait(5)
                    SetEntityAnimSpeed(ped, dict, anim, 1.0)
                    -- SetEntityAnimCurrentTime(ped, dict, anim, 1.0)
                    if IsDisabledControlJustReleased(0, Keys["W"]) then
                        StopAnimTask(ped, dict, anim, 0.0)
                        RequestAnimDict(dict)
                        while not HasAnimDictLoaded(dict) do
                            Citizen.Wait(2)
                        end
                        TaskPlayAnim(ped, dict, anim, 2.0, -8.0, -1, 35, 0, 0, 0, 0)
                        while true do
                            Citizen.Wait(5)
                            SetEntityAnimSpeed(ped, dict, anim, 0)
                            if IsDisabledControlPressed(0, Keys["W"]) then
                                break
                            end
                        end
                        break
                    end
                end
            end
        else
            StopAnimTask(ped, dict, anim, 2.0)
        end
    end
end)

local locale = {
    en = {
        EnterPushVehicleMessage = "Press [~g~SHIFT~w~] and [~g~E~w~] to push the vehicle mode",
        LeavePushVehicleMessage = "Press [~r~ESC~w~] to cancel"
    },
    th = {
        EnterPushVehicleMessage = "กด [~g~SHIFT~w~] พร้อมกับ [~g~E~w~] เพื่อดันรถ",
        LeavePushVehicleMessage = "กด [~r~ESC~w~] เพื่อออกจากการดันรถ"
    }
}
local currentLocale = 'en'

Citizen.CreateThread(function()
    local lerpCurrentAngle = 0.0
    while true do 
        Citizen.Wait(5)
        local ped = PlayerPedId()
        if Vehicle.Vehicle ~= nil then

            if IsVehicleSeatFree(Vehicle.Vehicle, -1) and GetVehicleEngineHealth(Vehicle.Vehicle) <= Config.DamageNeeded then
                QBCore.Functions.DrawText3D(Vehicle.Coords.x, Vehicle.Coords.y, Vehicle.Coords.z, locale[currentLocale].EnterPushVehicleMessage)
            end

            if IsControlPressed(0, Keys["LEFTSHIFT"]) and IsControlJustPressed(0, Keys["E"]) and IsVehicleSeatFree(Vehicle.Vehicle, -1) and not IsEntityAttachedToEntity(ped, Vehicle.Vehicle) and GetVehicleEngineHealth(Vehicle.Vehicle) <= Config.DamageNeeded then
                Vehicle.Pushable = true
            end

            if Vehicle.Pushable then
                NetworkRequestControlOfEntity(Vehicle.Vehicle)
                local coords = GetEntityCoords(ped)
                if Vehicle.IsInFront then    
                    AttachEntityToEntity(ped, Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y * -1 + 0.1 , Vehicle.Dimensions.z + 1.0, 0.0, 0.0, 180.0, 0.0, false, false, true, false, true)
                else
                    AttachEntityToEntity(ped, Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y - 0.1, Vehicle.Dimensions.z  + 1.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, true)
                end

                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do
                    Citizen.Wait(2)
                end
                TaskPlayAnim(ped, dict, anim, 2.0, -8.0, -1, 35, 0, 0, 0, 0)
                Citizen.Wait(200)
                
                local currentVehicle = Vehicle.Vehicle
                while true do
                    Citizen.Wait(5)
                    local speed = GetFrameTime() * 50
                    DisableAllControlActions(0)
                    EnableControlAction(0, Keys["LOOK_LR"], true)
                    EnableControlAction(0, Keys["LOOK_UD"], true)
                    QBCore.Functions.DrawText3D(Vehicle.Coords.x, Vehicle.Coords.y, Vehicle.Coords.z,  locale[currentLocale].LeavePushVehicleMessage)

                    if IsDisabledControlPressed(0, Keys["A"]) then
                        SetVehicleSteeringAngle(currentVehicle, lerpCurrentAngle)
                        lerpCurrentAngle = lerpCurrentAngle + speed
                    elseif IsDisabledControlPressed(0, Keys["D"]) then
                        SetVehicleSteeringAngle(currentVehicle, lerpCurrentAngle)
                        lerpCurrentAngle = lerpCurrentAngle - speed
                    else
                        SetVehicleSteeringAngle(currentVehicle, lerpCurrentAngle)
                        
                        --Don't immediatly snap tires to base position
                        if lerpCurrentAngle < -0.02 then    
                            lerpCurrentAngle = lerpCurrentAngle + speed
                        elseif lerpCurrentAngle > 0.02 then
                            lerpCurrentAngle = lerpCurrentAngle - speed
                        else
                            lerpCurrentAngle = 0.0
                        end
                    end
                    
                    -- Force the vehicle angles to stay at 15 to -15 degrees
                    if lerpCurrentAngle > 15.0 then
                        lerpCurrentAngle = 15.0
                    elseif lerpCurrentAngle < -15.0 then
                        lerpCurrentAngle = -15.0
                    end

                    if IsDisabledControlPressed(0, Keys["W"]) then
                        if Vehicle.IsInFront then
                            SetVehicleForwardSpeed(currentVehicle, -Config.PushMaxSpeed)
                        else
                            SetVehicleForwardSpeed(currentVehicle, Config.PushMaxSpeed)
                        end
                    end

                    if HasEntityCollidedWithAnything(currentVehicle) then
                        SetVehicleOnGroundProperly(currentVehicle)
                    end

                    if IsDisabledControlJustPressed(1, Keys["ESC"]) then
                        while true do
                            Citizen.Wait(2)
                            SetPauseMenuActive(false)
                            if IsDisabledControlJustReleased(1, Keys["ESC"])  then
                                Vehicle.Pushable = false
                                DetachEntity(ped, false, false)
                                FreezeEntityPosition(ped, false)
                                StopAnimTask(ped, dict, anim, 2.0)
                                Citizen.Wait(200)
                                break
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end)
