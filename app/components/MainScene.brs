sub init()
    m.output = m.top.findNode("output")
    m.output.text = "Loading nearby stops..."
    LoadNearbyBuses()
end sub

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

    lat = "37.856685"
    lon = "-122.264832"
    distance = "1000"

    stopsUrl = "https://api.actransit.org/transit/stops/" + lat + "/" + lon + "/" + distance + "/false/?token=" + token
    stops = HttpGetJson(stopsUrl)

    if stops = invalid or stops.Count() = 0
        m.output.text = "No stops found within " + distance + " ft"
        return
    end if

    lines = "Nearby stops (" + Str(stops.Count()).Trim() + ")" + Chr(10) + Chr(10)

    for each stop in stops
        stopId = stop.StopId
        stopName = stop.Name
        if stopName = invalid then stopName = "Stop " + Str(stopId).Trim()

        lines = lines + stopName + Chr(10)

        routesUrl = "https://api.actransit.org/transit/stops/" + Str(stopId).Trim() + "/routes?token=" + token
        routeData = HttpGetJson(routesUrl)

        if routeData <> invalid and routeData.Count() > 0
            for each r in routeData
                lines = lines + "  " + FormatJson(r) + Chr(10)
            end for
        else
            lines = lines + "  (no route/time data returned)" + Chr(10)
        end if

        lines = lines + Chr(10)
        m.output.text = lines
    end for
end sub
