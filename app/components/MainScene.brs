sub init()
    m.output = m.top.findNode("output")
    m.output.text = "Loading nearby stops..."
    m.reg = CreateObject("roRegistrySection", "BusScreensaver")

    m.loaderTask = m.top.findNode("loaderTask")
    m.loaderTask.observeField("resultText", "OnResultText")

    m.refreshTimer = m.top.findNode("refreshTimer")
    m.refreshTimer.duration = GetRegNumber("refresh", 60)
    m.refreshTimer.observeField("fire", "OnRefreshFire")
    m.refreshTimer.control = "start"

    StartLoad()
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

sub OnRefreshFire(event as Object)
    StartLoad()
end sub

sub StartLoad()
    token = ReadApiToken()
    if token = "" then
        m.output.text = "Missing API token at pkg:/components/token.txt"
        return
    end if

    m.loaderTask.lat = Str(GetRegNumber("lat", 37.856685)).Trim()
    m.loaderTask.lon = Str(GetRegNumber("lon", -122.264832)).Trim()
    m.loaderTask.distance = Str(Int(GetRegNumber("distance", 1000))).Trim()
    m.loaderTask.token = token
    m.loaderTask.control = "RUN"
end sub

sub OnResultText(event as Object)
    m.output.text = event.GetData()
end sub
