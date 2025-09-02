sub init()
    m.top.backgroundColor = "0x" + randomColor()
    m.top.backgroundUri = ""
    m.top.loadingIndicator = m.top.FindNode("loadingIndictaor")    

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
    m.top.backgroundColor = "0x" + randomColor()
end sub