sub init()
    m.top.setFocus(true)
    m.reg = CreateObject("roRegistrySection", "BusScreensaver")

    m.fields = [
        { label: "Latitude", key: "lat", value: GetRegNumber("lat", 37.856685), step: 0.001 }
        { label: "Longitude", key: "lon", value: GetRegNumber("lon", -122.264832), step: 0.001 }
        { label: "Distance (ft)", key: "distance", value: GetRegNumber("distance", 1000), step: 100, min: 100, max: 25000 }
        { label: "Refresh (sec)", key: "refresh", value: GetRegNumber("refresh", 60), step: 10, min: 10, max: 600 }
    ]
    m.selected = 0

    m.display = m.top.findNode("fieldsLabel")
    RenderFields()
end sub

function GetRegNumber(key as String, default as Float) as Float
    if m.reg.Exists(key) then return Val(m.reg.Read(key))
    return default
end function

sub RenderFields()
    text = ""
    for i = 0 to m.fields.Count() - 1
        f = m.fields[i]
        prefix = "  "
        if i = m.selected then prefix = "> "
        text = text + prefix + f.label + ": " + Str(f.value).Trim() + Chr(10)
    end for
    m.display.text = text
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "up"
        m.selected = (m.selected - 1 + m.fields.Count()) mod m.fields.Count()
        RenderFields()
        return true
    else if key = "down"
        m.selected = (m.selected + 1) mod m.fields.Count()
        RenderFields()
        return true
    else if key = "right"
        AdjustSelected(1)
        return true
    else if key = "left"
        AdjustSelected(-1)
        return true
    else if key = "back"
        SaveSettings()
        return false
    end if

    return false
end function

sub AdjustSelected(direction as Integer)
    f = m.fields[m.selected]
    f.value = f.value + (f.step * direction)
    if f.min <> invalid and f.value < f.min then f.value = f.min
    if f.max <> invalid and f.value > f.max then f.value = f.max
    m.fields[m.selected] = f
    RenderFields()
end sub

sub SaveSettings()
    for each f in m.fields
        m.reg.Write(f.key, Str(f.value).Trim())
    end for
    m.reg.Flush()
end sub
