-- must go to luce once finalised

--[[----------------------------------------------------------------------------

LDocument.lua

Create a Luce Document Window adapted to the host/target OS

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]
local LDEBUG = _G.LDEBUG
local luce   = _G.Luce
local app    = _G.App
local log, logError = app.log, app.logError

local className = "LDocument"

local mt = {}
mt.__index = mt

local function new(name, ...)
    local name = name or className
    -- pre-declaration
    local self = {
        name          = name,
        setFullScreen = nil,
        setSize       = nil,
        setBounds     = nil,
        closeWindow   = nil,
    }

    ---
    -- LDocument Class initialisation
    ---
    local this   = luce:DocumentWindow(name)
    local bounds = {0,0,800,600}
    local size   = {800, 600}
    -- TODO: set bounds instead of size, getting current bounds if a Point
    --       is provided
    local function set_size(size)
        if not(this) then return end
        if app.os.ios then
            if not(this:isFullScreen()) then
                this:setFullScreen(true) -- or kiosk ?
            end
        elseif app.os.android then
            if not(this:isFullScreen()) then
                this:setFullScreen(true) -- implement kiosk
            end
        else
            this:centreWithSize(size)
        end
    end
    function self:setFullScreen(state)
        if (app.os.ios or app.os.android) then
            if state == this:isFullScreen() then return end
            if("nil"==type(state))then state = not(this:isFullScreen()) end
            this:setFullScreen( state )
        else
            if state == this:isKioskMode() then return end
            if("nil"==type(state))then state = not(this:isKioskMode()) end
            this:setKioskMode(state)
        end
    end

    function self:setSize(size)
        set_size(size)
    end
 
    function self:setBounds(b)
        bounds = b
        size = { b.w, b.h }
        set_size(size)
    end

    function self:closeWindow()
        if(app.os.linux or app.os.win)then
            app:exit()
        else
            this:closeWindow()
        end
    end

    self.__self = this.__self
    return setmetatable(self, {
        __self  = this.__self,
        __index = this,
        __newindex = this,
        __tostring = function() return className.."("..name..")" end
    })
end

mt.__call = function(_, name, ...)
    return new(name, ...)
end

return setmetatable(mt, mt)
