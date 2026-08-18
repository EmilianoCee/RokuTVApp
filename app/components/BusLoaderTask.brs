sub init()
    m.top.functionName = "RunLoad"
end sub

sub RunLoad()
    token = m.top.token
    lat = m.top.lat
    lon = m.top.lon
    distance = m.top.distance

    m.top.statusText = ""
    m.top.stopBlocks = []

    stopsUrl = "https://api.actransit.org/transit/stops/" + lat + "/" + lon + "/" + distance + "/false/?token=" + token
    stops = HttpGetJson(stopsUrl)

    if stops = invalid or stops.Count() = 0 then
        m.top.statusText = "No stops found within " + distance + " ft"
        return
    end if

    maxStops = 12
    checked = 0
    blocks = []

    for each stopItem in stops
        if checked >= maxStops then exit for
        checked = checked + 1

        stopId = stopItem.StopId
        stopName = stopItem.Name
        if stopName = invalid then stopName = "Stop " + Str(stopId).Trim()

        block = stopName + Chr(10)

        predictionsUrl = "https://api.actransit.org/transit/stops/" + Str(stopId).Trim() + "/predictions?token=" + token
        predictions = HttpGetJson(predictionsUrl)

        if predictions <> invalid and predictions.Count() > 0 then
            for each p in predictions
                block = block + "  " + FormatPrediction(p) + Chr(10)
            end for
        else
            block = block + "  No upcoming buses" + Chr(10)
        end if

        blocks.Push(block)
        m.top.stopBlocks = blocks
    end for
end sub

function HttpGetJson(url as String) as Dynamic
    port = CreateObject("roMessagePort")
    req = CreateObject("roUrlTransfer")
    req.SetMessagePort(port)
    req.SetCertificatesFile("common:/certs/ca-bundle.crt")
    req.InitClientCertificates()
    req.SetUrl(url)
    req.EnableEncodings(true)

    if not req.AsyncGetToString() then return invalid

    msg = wait(5000, port)
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

    return invalid
end function

function FormatPrediction(p as Object) as String
    route = p.RouteName
    if route = invalid then route = "?"

    depart = p.PredictedDeparture
    timeStr = "?"
    if depart <> invalid and Len(depart) >= 16 then timeStr = Mid(depart, 12, 5)

    delaySec = p.PredictedDelayInSeconds
    delayStr = ""
    if delaySec <> invalid and delaySec <> 0 then
        delayMin = Int(Abs(delaySec) / 60)
        if delaySec > 0 then
            delayStr = " (delayed " + Str(delayMin).Trim() + " min)"
        else
            delayStr = " (" + Str(delayMin).Trim() + " min early)"
        end if
    end if

    return "Route " + route + " - " + timeStr + delayStr
end function
