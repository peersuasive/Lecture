-- must go to luce once finalised

--[[----------------------------------------------------------------------------

LApplication.lua

Create a Luce Application adapted to the host/target OS

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]
local LDEBUG = _G.LDEBUG
local luce   = nil

local className = "LApplication"

local mt = {}
mt.__index = mt

    -- function pour initialiser les composants plus tard
    -- 
    --[[
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

-- TODO: luce:shutdown() -- when ? how ?
local function new(name, ...)
    local name = name or className
    local args = {...}
    -- pre-declaration
    local self = {
        args     = args,
        name     = name,
        log      = nil,
        logError = nil,
        start    = nil,
        exit     = nil,
        os       = nil,
    }

    ---
    -- specific useful directories and parameters
    ---
    local OS      = {
        unix      = os.getenv("HOME") and true,
        win       = os.getenv("HOMEDRIVE") and true,
        linux     = nil,
        osx       = (os.getenv("HOME") or ""):match("^/Users") and true,
        ios       = (os.getenv("HOME") or ""):match("^/var/mobile") and true,
        android   = os.getenv('ANDROID_DATA') and true,
    }
    local HOME    = luce.JUCEApplication.userHomeDirectory()
    local TMP     = (OS.linux or OS.osx) and "/tmp" or luce.JUCEApplication.tempDirectory()
    local DOCS    = luce.JUCEApplication.userDocumentsDirectory()
    local DATA    = luce.JUCEApplication.userApplicationDataDirectory()
    local sep     = OS.unix and "/" or "\\"
    local so      = OS.unix and "so" or "dll"
    OS.linux      = OS.unix and not(OS.osx or OS.ios)
    self.os       = OS
    local has_stdout = (OS.linux or OS.win) and true

    -- some default path when semi-embedded
    -- look in $HOME/.luce for classes and modules first
    -- NOTE: should add ./ too
    local luce_lib = HOME..sep..".luce"..sep.."lib"..sep.."?.".. so
    luce_lib       = luce_lib..";"..HOME..sep..".luce"..sep.."lib"..sep.."?"..sep.."?.".. so..";"
    local luce_lua = HOME..sep..".luce"..sep.."lua"..sep.."?.lua"
    luce_lua       = luce_lua..";"..HOME..sep..".luce"..sep.."lua"..sep.."?"..sep.."?.lua"..";"
    package.path   = luce_lua..package.path
    package.cpath  = luce_lib..package.cpath

    ---
    -- utils
    ---
    local log_file = (LDEBUG or not(has_stdout))
                        and io.open(TMP..sep.."luce."..name..".log", "wb")
                        or io.stdout

    -- TODO: depending on OS, choose to save in log
    --       or to display an alert window (Windows and Mac OS X, for instance)
    local function log(msg, ...)
        local msg = (msg or "").."\n"
        log_file:write(string.format(msg, ...))
        log_file:flush()
    end
    local function logError(msg, ...)
        local msg = "Error: "..(msg or "")
        log(msg, ...)
        self:exit(1)
    end
    self.log      = log
    self.logError = logError
    _G.Log        = log
    _G.LogError   = logError

    local function shift(i)
        local i = i or 1
        local v = args[i]
        table.remove(args, i)
        return v
    end
    local _assert = assert
    local function assert(truth, ...)
        if(truth)then return truth end
        logError(...)
    end

    ---
    -- LApplication Class initialisation
    ---
    local lapp        = luce:JUCEApplication(name)
    local MainClass   = nil -- provided by start
    local backgroundColour = luce.Colours.white

    ----
    --- Document Window management
    --- TODO: create a LDocumentWindow class to wrap these methods and have direct call ?
    ---       that'd be safer than passing uncheckable components
    ----

    local bounds = {0,0,800,600}
    local size   = {800, 600}
    -- TODO: set bounds instead of size, getting current bounds if a Point
    --       is provided
    local function set_size(documentWindow, size)
        if not(documentWindow) then return end
        if OS.ios then
            if not(documentWindow:isFullScreen()) then
                documentWindow:setFullScreen(true) -- or kiosk ?
            end
        elseif OS.android then
            if not(documentWindow:isFullScreen()) then
                documentWindow:setFullScreen(true) -- implement kiosk
            end
        else
            documentWindow:centreWithSize(size) -- os x ?
        end
    end
    function self:setFullScreen(documentWindow, state)
        if not(documentWindow) then return end
        if (OS.ios or OS.android) then
            if state == documentWindow:isFullScreen() then return end
            if("nil"==type(state))then state = not(documentWindow:isFullScreen()) end
            documentWindow:setFullScreen( state )
        else
            if state == documentWindow:isKioskMode() then return end
            if("nil"==type(state))then state = not(documentWindow:isKioskMode()) end
            documentWindow:setKioskMode(state)
        end
    end

    function self:setSize(documentWindow, size)
        set_size(documentWindow, size)
    end
 
    function self:setBounds(documentWindow, b)
        bounds = b
        size = { b.w, b.h }
        set_size(documentWindow, size)
    end
    local n = 0
    local function initialise(...)
        n = n+1
        local extra = not(tostring(...)=="") and {...} or {}
        local params = {}
        for _,v in next,args  do params[#params+1] = v end
        for _,v in next,extra do params[#params+1] = v end
        --local dw = luce:DocumentWindow(name..":"..n)
        --local comp = MainClass(dw, params)
        --return dw
        return MainClass(params)
    end

    function self:setBackgroundColour(colour)
        backgroundColour = colour
    end

    ---
    -- LApplication implementation
    ---
    lapp:resumed(function(...)
        -- android
        if (OS.android) then
            return initialise(...)
        end
    end)
    lapp:anotherInstanceStarted(function(...)
        -- osx (and ios ?)
        if (OS.osx) then
            return initialise(...)
        end
    end)
    lapp:initialise(function(...)
        -- linux and windows (and ios ?)
        if (OS.linux or OS.win) then
            return initialise(...)
        end
    end)

    function self:start(mainClass, wsize, wants_control, poller_cb)
        MainClass = mainClass
        size = wsize or {800,600}
        return luce:start( lapp )
    end

    function self:exit(state)
        lapp:shutdown()
        lapp:quit(status)
        --luce:shutdown() -- TODO: check
    end
    function self:quit(state)
        self:exit(state)
    end

    self.initialised = lapp.initialised
    return setmetatable(self, {
        __index = lapp,
        __newindex = lapp,
        __tostring = function() return className.."("..name..")" end
    }), luce
end

mt.__call = function(_, name, ...)
    local args = {...}
    lDEBUG  = args[1] and args[1]:match("^[Dd]$") and table.remove(args,1) and true
    luce    = require"luce"(lDEBUG)
    _G.Luce = luce
    _G.App  = new(name, unpack(args))
    return _G.App, luce
end

return setmetatable(mt, mt)
