--[[----------------------------------------------------------------------------

Lecture (main.lua)

Lecture, The Luce Written In One Shot Omni Platform Comics Reader

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

local app, luce = require"LApplication"("Lecture", ...)

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

--[[-- rst

    dans app, j'ai

       args: les paramètres fournis au lancement, s'il y en a
         os: l'OS sur lequel s'exécute l'appli: unix, linux, osx, android, ios, win
       init: le callback initialise auquel je fournis ma classe principale et les classes
             complémentaires
    kevents: les événements input, clavier, souris, touch, etc...
      paint: callback paint du composant principal
    resized: callback resized du composant principal
initialised: callback appelé lorsque l'application a terminé son initisalisation
      start: la function qui démarre la boucle principale, à laquelle je peux fournir
             un callback qui sera exécuté à chaque appel; l'effet est différent selon l'os,
             le callback n'est pour le moment disponible que pour Linux et Windows.
       exit: quitte l'application avec le code de sortie ou 0 
        log: enregistre dans le log ou affiche dans le terminal
   logError: enregistre dans le log d'erreur ou affiche dans le terminal et quitte l'application
--]]

-- MainWindow component, the core of the application
-- it'll be called by the Application class once the environment
-- is ready to show something
local nb = 0
local function MainWindow(params)
    local app, luce = app, luce -- shortcutst
    local is_mobile = app.os.ios or app.os.android 
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
    local mc = luce:MainComponent("MainComponent:"..nb)
    mc:setSize(wsize)

    mc:addAndMakeVisible(comp)

    -- document window
    local documentWindow = require"LDocument"(bookName)
    documentWindow:setBackgroundColour( luce.Colours.black )

    documentWindow:setContentOwned( mc, true )

    -- some key actions
    local K = string.byte
    local kc = setmetatable( luce.KeyPress.KeyCodes, { __index = function()return 0 end })
    documentWindow:keyPressed(function(k)
        local k, m = k:getKeyCode(), k:getModifiers()

        if (k==K"F" or k==K"f") and ( not(app.os.osx) and true or m:isCommandDown() ) then
            documentWindow:setFullScreen()
            return true

        elseif not(app.os.osx) and (k==K"Q" or k==K"q") then
            app:exit()
            return true

        elseif (k==K"w" or k==K"W") and (m:isCommandDown() ) then
            documentWindow:closeWindow()
            return true

        else
            return comp:userKeyEvent(k,m)
        end
    end)

    mc:resized(function(...)
        comp:setBounds( mc:getBounds() )
    end)

    documentWindow:closeButtonPressed(function()
        documentWindow:closeWindow()
    end)

    documentWindow:setVisible(true)

    -- TODO: wrap this or create a LDocumentWindow class,
    --       the name app is too confusing
    documentWindow:setSize{w, screenH}

    return documentWindow
end

app:moreThanOneInstanceAllowed(function()
    return false
end)

app:systemRequestedQuit(function()
    app:exit()
end)

local manual = false         -- gives control over the main loop
                             -- implemented for Linux and Windows only at the moment
local poller = function()end -- id.
return app:start( MainWindow, size, manual, manual and poller )
