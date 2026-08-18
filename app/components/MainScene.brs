sub init()
    m.output = m.top.findNode("output")
    m.output.text = "Loading nearby stops..."
    m.reg = CreateObject("roRegistrySection", "BusScreensaver")

    m.refreshTimer = m.top.findNode("refreshTimer")
    m.refreshTimer.duration = GetRegNumber("refresh", 60)
    m.refreshTimer.observeField("fire", "LoadNearbyBuses")
    m.refreshTimer.control = "start"

    LoadNearbyBuses()
end sub

function GetRegNumber(key as String, default as Float) as Float
    if m.reg.Exists(key) then return Val(m.reg.Read(key))
    return default
end function

function ReadApiToken() as String
    tokenText = ReadAsciiFile("pkg:/components/token.txt")
    if tokenText = invalid then return ""
    return tokenText.trim()
end function

function HttpGetJson(url as String) as Dynamic
    port = CreateObject("roMessagePort")
    req = CreateObject("roUrlTransfer")
    req.SetMessagePort(port)
    req.SetCertificatesFile("common:/certs/ca-bundle.crt")
    req.InitClientCertificates()
    req.SetUrl(url)
    req.EnableEncodings(true)

    if not req.AsyncGetToString() then return invalid

    while true
        msg = wait(10000, port)
        if msg = invalid then
            req.AsyncCancel()
            print "Request timed out: "; url
            return invalid
        end if

        if type(msg) = "roUrlEvent" then
            code = msg.GetResponseCode()
            if code = 200 then
                return ParseJson(msg.GetString())
            else
                print "HTTP "; code; " for "; url
                return invalid
            end if
        end if
    end while
end function

sub LoadNearbyBuses()
    token = ReadApiToken()
    if token = ""
        m.output.text = "Missing API token at pkg:/components/token.txt"
        return
    end if

    lat = Str(GetRegNumber("lat", 37.856685)).Trim()
    lon = Str(GetRegNumber("lon", -122.264832)).Trim()
    distance = Str(Int(GetRegNumber("distance", 1000))).Trim()

    stopsUrl = "https://api.actransit.org/transit/stops/" + lat + "/" + lon + "/" + distance + "/false/?token=" + token
    stops = HttpGetJson(stopsUrl)

    if stops = invalid or stops.Count() = 0
        m.output.text = "No stops found within " + distance + " ft"
        return
    end if

    lines = "Nearby stops (" + Str(stops.Count()).Trim() + ")" + Chr(10) + Chr(10)
    m.output.text = lines

    for each stop in stops
        stopId = stop.StopId
        stopName = stop.Name
        if stopName = invalid then stopName = "Stop " + Str(stopId).Trim()

        lines = lines + stopName + Chr(10)

        predictionsUrl = "https://api.actransit.org/transit/stops/" + Str(stopId).Trim() + "/predictions?token=" + token
        predictions = HttpGetJson(predictionsUrl)

        if predictions <> invalid and predictions.Count() > 0
            for each p in predictions
                lines = lines + "  " + FormatPrediction(p) + Chr(10)
            end for
        else
            lines = lines + "  No upcoming buses" + Chr(10)
        end if

        lines = lines + Chr(10)
        m.output.text = lines
    end for
end sub

function FormatPrediction(p as Object) as String
    route = p.RouteName
    if route = invalid then route = "?"

    depart = p.PredictedDeparture
    timeStr = "?"
    if depart <> invalid and Len(depart) >= 16 then timeStr = Mid(depart, 12, 5)

    delaySec = p.PredictedDelayInSeconds
    delayStr = ""
    if delaySec <> invalid and delaySec <> 0
        delayMin = Int(Abs(delaySec) / 60)
        if delaySec > 0
            delayStr = " (delayed " + Str(delayMin).Trim() + " min)"
        else
            delayStr = " (" + Str(delayMin).Trim() + " min early)"
        end if
    end if

    return "Route " + route + " - " + timeStr + delayStr
end function
