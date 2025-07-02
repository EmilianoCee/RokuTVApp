'*************************************************************
'** e cereceres
'** 2025
'*************************************************************

sub main()
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    'Create a scene and load /components/MainScene.xml'
    scene = screen.CreateScene("Scene2910")
    screen.show()

    'Event loop
    while(true)
        msg = wait(0, m.port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        end if
    end while
end sub

