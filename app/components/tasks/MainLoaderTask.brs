sub init()
    m.top.functionName = "loadBusData"
    m.loaderTask = CreateObject("roSGNode", "MainLoaderTask")
end sub

function loadBusData()
    stopID = 58234
    busData = GetBusDataForStop(stopID)
    m.top.busList = busData
end function

function GetBusDataForStop(stopID as Integer) as Object
    xfer = CreateObject("roURLTransfer")
    file = CreateObject("roFileSystem")
    
    if file.Exists("tmp:/token.txt")
        token = file.ReadFile("tmp:/token.txt")
    else
        print "Token file not found!"
        return []
    end if

    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")

    ' Fetch predictions
    url = "http://api.actransit.org/transit/stop/" + stopID.ToStr() + "/predictions?token=" + token
    xfer.SetURL(url)
    rsp = xfer.GetToString()

    if rsp = invalid or rsp = "" then return []

    predictions = ParseJson(rsp)
    if predictions = invalid then return []

    ' Prepare output array
    busData = []

    for each pred in predictions
        route = pred.RouteName
        vehicleID = pred.VehicleID.ToStr()

        ' Get vehicle location
        locUrl = "http://webservices.nextbus.com/service/publicJSONFeed?command=vehicleLocations&a=actransit&r=" + route + "&t=0"
        xfer.SetURL(locUrl)
        vehicleRsp = xfer.GetToString()

        secsAgo = ""

        if vehicleRsp <> invalid and vehicleRsp <> ""
            vehicleJson = ParseJson(vehicleRsp)
            if vehicleJson <> invalid and vehicleJson.vehicle <> invalid
                for each v in vehicleJson.vehicle
                    if v.id = vehicleID
                        secsAgo = v.secsSinceReport
                        exit for
                    end if
                end for
            end if
        end if

        ' Build each entry as an AA
        item = {
            RouteName:     pred.RouteName
            Direction:     pred.Direction
            Prediction:    pred.Prediction
            VehicleID:     vehicleID
            Destination:   pred.Destination
            SecondsAgo:    secsAgo
        }
        busData.Push(item)
    end for

    return busData
end function
