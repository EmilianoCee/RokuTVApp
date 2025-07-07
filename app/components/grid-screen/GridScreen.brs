sub Init()
    m.rowList = m.top.FindNode("rowList")
    m.rowList.setFocus(true)
    m.descriptionLabel = m.top.FindNode("descriptionLabel")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.rowList.ObserveField("rowItemFocused", "OnItemFocused")
end sub

sub OnItemFocused()
    focusedIndex = m.rowList.rowItemFocused
    row = m.rowList.content.GetChild(focusedIndex[0])
    item = row.GetChild(focusedIndex[1])

    m.descriptionLabel.text = item.description
    m.titleLabel.text = item.title
    if item.length <> invalid
        m.titleLabel.text += " | 2910"
    end if
end sub
