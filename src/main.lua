--[[----------------------------------------------------------------------------

Lecture (main.lua)

Lecture, The Luce Written In One Shot Omni Platform Comics Reader

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local luce = require"luce"
local app, luce = require"luce.LApplication"("Lecture", ...)

local log, logError = app.log, app.logError

local function help(msg)
    local msg = msg and "Error: "..msg.."\n" or ""
    local sc = [[available shortcuts:
    space/right    -> next page
    backspace/left -> previous page
    home           -> 1st page
    end            -> last page
    f              -> toggle full screen
    s              -> toggle info (above image)
    S              -> toggle info (below image)
    q/ctrl-q       -> quit]]
    msg = string.format("%sUsage: %s <book>\n\n%s", msg, "lecture", sc)
    return msg
end

-- MainWindow component, the core of the application
-- it'll be called by the Application class once the environment
-- is ready to show something
local nb = 0
local function MainWindow(params)
    local app, luce = app, luce  -- shortcuts
    local Colours   = luce.Colours -- id.
    local is_mobile = app.os.ios or app.os.android 

    local documentWindow = luce:Document(bookName)
    local mc        = luce:MainComponent("MainComponent:"..nb)

    local comp      = nil -- the child component, ImageContainer for Desktops, ImageList for mobiles

    local imageSize = luce:Point{800,600} -- default size
    local bookName  = "Lecture" -- default name

    local cached, preloaded, startIndex = 3, 3 -- some default parameters for ImageContainer

    nb = nb+1
    if(is_mobile)then
        -- TODO
        -- instanciate a shelf
        -- then from the shelf, call ImageContainer
    else
        -- if the user provided a book, open it
        -- otherwise, show usage and exit
        -- TODO: add a menu with "Open..." for osx
        local book = params[1]
        if not (book) then log(help()); app:exit(1) end

        comp = require"ImageContainer"("BookDisplay:"..nb)

        -- some parameters for ImageContainer
        if not(app.ios or app.android) then
            cached, preloaded = 0, 0
        end
        local r, e, size, title = comp:setBook( book, cached, preloaded, startIndex )
        if not(r) then
            logError("Couldn't read book: %s", (e or "<no message>"))
        end

        imageSize = size or imageSize
        bookName = (title or bookName)..":"..nb
    end
 
    -- compute size of the window from image size
    local screenH = 1
    local displays = luce.DocumentWindow.Displays()
    for _,d in next, displays do
        if(d.isMain)then
            screenH = luce:Rectangle(d.userArea):getHeight() - 50 -- title bar size, get this val from somewhere
            break
        end
    end
    local w = screenH * ( imageSize.x / imageSize.y )
    local wsize = { w, screenH }

    -- main component
    if(comp)then
        mc:addAndMakeVisible(comp)
        mc:resized(function(...)
            comp:setBounds( mc:getBounds() )
        end)
    end

    -- some key actions
    local K = string.byte
    local kc = setmetatable( luce.KeyPress.KeyCodes, { __index = function()return 0 end })
    documentWindow:keyPressed(function(k)
        local k, m = k:getKeyCode(), k:getModifiers()

        if (k==K"F" or k==K"f") and ( not(app.os.osx) and true or m:isCommandDown() ) then
            documentWindow:setFullScreen()
            return true

        elseif (k==K"Q" or k==K"q") and (m:isCommandDown() or not(app.os.osx)) then
            app:exit()
            return true

        elseif (k==K"w" or k==K"W") and (m:isCommandDown() ) then
            documentWindow:closeWindow()
            return true

        else
            if(comp and comp.userKeyEvent)then
                return comp:userKeyEvent(k,m)
            else
                return false
            end
        end
    end)

    -- document window
    mc:setSize(wsize)
    documentWindow:setBackgroundColour( Colours.black )
    documentWindow:setContentOwned( mc, true )
    documentWindow:setSize{w, screenH}
    documentWindow:setVisible(true)

    return documentWindow
end

app:moreThanOneInstanceAllowed(function()
    return false
end)

app:systemRequestedQuit(function()
    app:exit()
end)

local manual      = false      -- gives control over the main loop (not supported by iOS and Android a.t.m.)
local osx_delayed = false      -- if we want OS X app to start with a window or wait for user actions, like dropping a file, etc.
local has_shown = false
local poller      = function() -- a callback to provide controlled loop with
    if not(has_shown)then
        print "I'm in the main loop! I could do some useful things..."
        has_shown = true
    end
end
return app:start( MainWindow, manual and poller, osx_delayed )
