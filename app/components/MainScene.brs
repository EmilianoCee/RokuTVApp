sub init()
    m.outputLeft = m.top.findNode("outputLeft")
    m.outputRight = m.top.findNode("outputRight")
    m.outputLeft.text = "Loading nearby stops..."
    m.outputRight.text = ""
    m.reg = CreateObject("roRegistrySection", "BusScreensaver")

    m.loaderTask = m.top.findNode("loaderTask")
    m.loaderTask.observeField("statusText", "OnStatusText")
    m.loaderTask.observeField("stopBlocks", "OnStopBlocks")

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
        m.outputLeft.text = "Missing API token at pkg:/components/token.txt"
        m.outputRight.text = ""
        return
    end if

    m.outputLeft.text = "Loading nearby stops..."
    m.outputRight.text = ""

    m.loaderTask.lat = Str(GetRegNumber("lat", 37.856685)).Trim()
    m.loaderTask.lon = Str(GetRegNumber("lon", -122.264832)).Trim()
    m.loaderTask.distance = Str(Int(GetRegNumber("distance", 1000))).Trim()
    m.loaderTask.token = token
    m.loaderTask.control = "RUN"
end sub

sub OnStatusText(event as Object)
    msg = event.GetData()
    if msg <> "" then
        m.outputLeft.text = msg
        m.outputRight.text = ""
    end if
end sub

sub OnStopBlocks(event as Object)
    blocks = event.GetData()
    if blocks = invalid or blocks.Count() = 0 then return

    half = Int((blocks.Count() + 1) / 2)

    leftText = ""
    for i = 0 to half - 1
        leftText = leftText + blocks[i] + Chr(10)
    end for

    rightText = ""
    for i = half to blocks.Count() - 1
        rightText = rightText + blocks[i] + Chr(10)
    end for

    m.outputLeft.text = leftText
    m.outputRight.text = rightText
end sub
