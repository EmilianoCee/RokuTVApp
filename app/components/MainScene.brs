sub init()
    ' m.top.setFocus(true)
    m.top.backgroundColor = "0x" + randomColor()
    
    m.myLabel = m.top.findNode("loadingIndicator")
    m.myLabel.text = "GOOOON" 
    m.myLabel.font.size = 92

    tokenText = ReadAsciiFile("pkg:/components/tasks/token.txt")
    if tokenText <> invalid and tokenText <> ""
        ' Trim common line endings
        m.myLabel.text = tokenText.trim()
    else
        m.myLabel.text = "No token found"
    end if
    call()

    m.colorTimer = m.top.findNode("colorTimer")
    m.colorTimer.observeField("fire", "randomBackground")
    m.colorTimer.control = "start"
end sub

sub onBusListReady()
    data = m.loaderTask.busList
    m.busList = data

    ' If you're binding directly to a UI component (like MarkupList)
    m.top.findNode("busListUI").content = CreateContentList(data)
end sub

' Optional helper to convert to ContentNodes
function CreateContentList(data as Object) as Object
    contentList = CreateObject("roSGNode", "ContentNode")
    for each bus in data
        node = CreateObject("roSGNode", "ContentNode")
        node.title = "Route " + bus.RouteName + " - " + bus.Direction
        node.shortDescriptionLine1 = "Arrives in " + bus.Prediction + " min"
        node.shortDescriptionLine2 = "To " + bus.Destination
        contentList.AppendChild(node)
    end for
    return contentList
end function

function randomColor() as String
    dim hexVals[16]
    hexVals = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
    parts = []
    for i = 0 to 5
        idx = rnd(16) - 1  ' rnd(16) gives 1..16, shift to 0..15
        parts.push(hexVals[idx])
    end for

    return parts.Join("")
end function

sub randomBackground()
    m.top.findNode("loadingIndicator").color = "0x" + randomColor()
end sub

function GetPredictionsResponse(stopId as integer) as dynamic
    ' 1) Read token from package
    tokenText = ReadAsciiFile("pkg:/components/tasks/token.txt")
    if tokenText = invalid or tokenText.trim() = "" then
        print "Token not found or empty at pkg:/components/tasks/token.txt"
        return invalid
    end if
    token = tokenText.trim()

    ' 2) Build URL
    base = "https://api.actransit.org/transit/stop/" + stopId.ToStr() + "/destinations"
    url  = base + "?token=" + token

    ' 3) Prepare request (HTTPS certs recommended)
    port = CreateObject("roMessagePort")
    req  = CreateObject("roUrlTransfer")
    req.SetMessagePort(port)
    req.SetCertificatesFile("common:/certs/ca-bundle.crt")
    req.InitClientCertificates()
    req.SetUrl(url)

    ' Optional but helpful for compressed responses
    req.EnableEncodings(true)
    ' If calling from a Task, you can set a request timeout via your own wait loop

    ' 4) Send async request
    if not req.AsyncGetToString() then
        print "AsyncGetToString failed to initiate"
        return invalid
    end if

    ' 5) Wait for response event
    while true
        msg = wait(10000, port) ' 10s overall timeout
        if msg = invalid then
            ' Cancel if timed out
            req.AsyncCancel()
            print "Request timed out"
            return invalid
        end if

        if type(msg) = "roUrlEvent" then
            code = msg.GetResponseCode()
            if code = 200 then
                s = msg.GetString()
                ' Optional: strip UTF-8 BOM if present to avoid ParseJSON issues later
                if left(s, 3) = chr(239) + chr(187) + chr(191) then
                    s = mid(s, 4)
                end if
                return s
            else
                print "HTTP error "; code; " reason="; msg.GetFailureReason()
                return invalid
            end if
        else
            ' Ignore unrelated events
        end if
    end while
end function

sub call()
    resp = GetPredictionsResponse(58234)
    if resp <> invalid then
        ' If needed later:
        ' data = ParseJSON(resp)
        m.myLabel.text = resp ' or format a shorter summary
    else
        m.myLabel.text = "Request failed"
    end if
end sub