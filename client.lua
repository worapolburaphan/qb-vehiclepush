local QBCore = exports['qb-core']:GetCoreObject()

Config = {} 
Config.DamageNeeded = 900 -- 100.0 being broken and 1000.0 being fixed a lower value than 100.0 will break it
Config.MaxWidth = 5.0 -- Will complete soon
Config.MaxHeight = 5.0
Config.MaxLength = 5.0
Config.PushMaxSpeed = 0.7
Config.PullMaxSpeed = 0.3

local Keys = {
  ["E"] = 38, ["A"] = 34, ["D"] = 9, ["W"] = 32, ["S"] = 33, ["LEFTSHIFT"] = 21
}

local First = vector3(0.0, 0.0, 0.0)
local Second = vector3(5.0, 5.0, 5.0)

local Vehicle = {Coords = nil, Vehicle = nil, Dimension = nil, IsInFront = false, Distance = nil, PushToggled = false}

Citizen.CreateThread(function()
    Citizen.Wait(200)
    while true do
        local ped = PlayerPedId()
        local closestVehicle, Distance = QBCore.Functions.GetClosestVehicle()
        local vehicleCoords = GetEntityCoords(closestVehicle)
        local vehicleForwardVector =  GetEntityForwardVector(closestVehicle)
        local dimension = GetModelDimensions(GetEntityModel(closestVehicle), First, Second)
        if Distance < 6.0 and (DoesEntityExist(closestVehicle) and IsEntityAVehicle(closestVehicle)) and not IsPedInAnyVehicle(ped, false) then
            Vehicle.Coords = vehicleCoords
            Vehicle.Dimensions = dimension
            Vehicle.Vehicle = closestVehicle
            Vehicle.Distance = Distance
            Vehicle.IsInFront = GetDistanceBetweenCoords(vehicleCoords + vehicleForwardVector, GetEntityCoords(ped), true) < GetDistanceBetweenCoords(vehicleCoords + vehicleForwardVector * -1, GetEntityCoords(ped), true)
        else
            Vehicle = {Coords = nil, Vehicle = nil, Dimensions = nil, IsInFront = false, Distance = nil, PushToggled = false}
        end
        Citizen.Wait(500)
    end
end)
 
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if Vehicle.PushToggled then
            if IsDisabledControlPressed(0, Keys["W"]) then
                RequestAnimDict('missfinale_c2ig_11')
                while not HasAnimDictLoaded("missfinale_c2ig_11") do
                    Citizen.Wait(2)
                end
                TaskPlayAnim(ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
                Citizen.Wait(200)
            elseif IsDisabledControlPressed(0, Keys["S"]) then
                RequestAnimDict('missheist_agency3amcs_2')
                while not HasAnimDictLoaded("missheist_agency3amcs_2") do
                    Citizen.Wait(2)
                end
                TaskPlayAnim(ped, 'missheist_agency3amcs_2', 'pull_driver_cam', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
                Citizen.Wait(200)
            end
        else 
            FreezeEntityPosition(ped, false)
        end
    end
end)

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(5)
        local ped = PlayerPedId()
        if Vehicle.Vehicle ~= nil then

            -- QBCore.Functions.DrawText3D(Vehicle.Coords.x, Vehicle.Coords.y, Vehicle.Coords.z + 1, "[~g~Engine Health" .. GetVehicleEngineHealth(Vehicle.Vehicle) .. "~w~]")
            if IsVehicleSeatFree(Vehicle.Vehicle, -1) and GetVehicleEngineHealth(Vehicle.Vehicle) <= Config.DamageNeeded then
                QBCore.Functions.DrawText3D(Vehicle.Coords.x, Vehicle.Coords.y, Vehicle.Coords.z, "Press [~g~SHIFT~w~] and [~g~E~w~] to push the vehicle mode")
            end

            if IsControlPressed(0, Keys["LEFTSHIFT"]) and IsControlJustPressed(0, Keys["E"]) and IsVehicleSeatFree(Vehicle.Vehicle, -1) and not IsEntityAttachedToEntity(ped, Vehicle.Vehicle) and GetVehicleEngineHealth(Vehicle.Vehicle) <= Config.DamageNeeded then
                Vehicle.PushToggled = true
            end

            if Vehicle.PushToggled then
                FreezeEntityPosition(ped, true)
                NetworkRequestControlOfEntity(Vehicle.Vehicle)
                local coords = GetEntityCoords(ped)
                if Vehicle.IsInFront then    
                    AttachEntityToEntity(ped, Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y * -1 + 0.1 , Vehicle.Dimensions.z + 1.0, 0.0, 0.0, 180.0, 0.0, false, false, true, false, true)
                else
                    AttachEntityToEntity(ped, Vehicle.Vehicle, GetPedBoneIndex(6286), 0.0, Vehicle.Dimensions.y - 0.3, Vehicle.Dimensions.z  + 1.0, 0.0, 0.0, 0.0, 0.0, false, false, true, false, true)
                end

                RequestAnimDict('missheist_agency3amcs_2')
                while not HasAnimDictLoaded("missheist_agency3amcs_2") do
                    Citizen.Wait(2)
                end
                TaskPlayAnim(ped, 'missheist_agency3amcs_2', 'pushcar_waitidle_additive_m', 2.0, -8.0, -1, 35, 0, 0, 0, 0)
                Citizen.Wait(200)

                local currentVehicle = Vehicle.Vehicle
                while true do
                    Citizen.Wait(5)
                    QBCore.Functions.DrawText3D(Vehicle.Coords.x, Vehicle.Coords.y, Vehicle.Coords.z, "Press [~g~SHIFT~w~] and [~g~E~w~] to exist push the vehicle")
                    if IsDisabledControlPressed(0, Keys["A"]) then
                        TaskVehicleTempAction(ped, currentVehicle, 11, 1000)
                    elseif IsDisabledControlPressed(0, Keys["D"]) then
                        TaskVehicleTempAction(ped, currentVehicle, 10, 1000)
                    end

                    if IsDisabledControlPressed(0, Keys["W"]) then
                        if Vehicle.IsInFront then
                            SetVehicleForwardSpeed(currentVehicle, -Config.PushMaxSpeed)
                        else
                            SetVehicleForwardSpeed(currentVehicle, Config.PushMaxSpeed)
                        end
                    elseif IsDisabledControlPressed(0, Keys["S"]) then
                        if Vehicle.IsInFront then
                            SetVehicleForwardSpeed(currentVehicle, Config.PullMaxSpeed)
                        else
                            SetVehicleForwardSpeed(currentVehicle, -Config.PullMaxSpeed)
                        end
                    end

                    if HasEntityCollidedWithAnything(currentVehicle) then
                        SetVehicleOnGroundProperly(currentVehicle)
                    end

                    if IsControlPressed(0, Keys["LEFTSHIFT"]) and IsControlJustPressed(0, Keys["E"]) then
                        DetachEntity(ped, false, false)
                        FreezeEntityPosition(ped, false)
                        Vehicle.PushToggled = false
                        break
                    end
                end
            end
        end
    end
end)
