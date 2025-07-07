sub init()
    m.top.backgroundColor = "0x6f1bb1"
    m.top.backgroundUri = ""
    m.top.loadingIndicator = m.top.FindNode("loadingIndictaor")

    
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
