--[[----------------------------------------------------------------------------

 ImageContainer.lua

 Main IHM, display images and show buttons, manage clicks...

    @alias meta

    @author Christophe Berbizier (cberbizier@peersuasive.com)
    @license GPLv3
    @copyright 

(c) 2014, Peersuasive Technologies

------------------------------------------------------------------------------]]

-- TODO: put image in a container, maybe a wiewport, to get a zoom

local luce, log, logError = Luce, Log, LogError

local componentName = "ImageContainer"

local image_info = function(image, filename, position, total, n, size)
    local w = image:getWidth()
    local h = image:getHeight()
    local r = h/w
    return {
        filename = filename:gsub(".*[/\\]([^/\\]+)", "%1"),
        position = position,
        total = total,
        n = n,
        size = size,
        width = w,
        height = h,
        ratio = r,
    }
end

local image_cache = function(book, icache, ipreload, iindex)
    local icache, ipreload, iindex = icache or 3, ipreload or 3, iindex or 1
 
    local arch, e = require"arch"( book )
    if not arch then return nil, e end

    local imageList, e = arch:list()
    if not imageList then return nil, e end

    return {
        index       = iindex,
        cache_size  = icache,
        spreload    = ipreload,
        total       = #imageList,

        cache = setmetatable({ n = 0 }, 
        { __newindex = function(self, k, v)
            self.n = v and (self.n+1) or self.n
            rawset(self,k,v)
        end }),

        add = function(self,i)
            assert(i, "Missing index")
            local n = imageList[i]
            if not(n)then return nil, string.format("invalid index: %s",i or "nil") end
            if self.cache[n] then return n end
            local data = arch:get( n )
            if not(data)then return nil, string.format("no data decoded") end
            self.cache[n] = luce.Image:getFromMemory( data )
            return n
        end,

        loaded = function(self,i)
            return self.cache[imageList[i]] and true or false
        end,

        current = function(self)
            return self.index, imageList[self.index]
        end,

        get = function(self,i)
            self:clear( (i<self.index) )
            local n = assert( self:add(i) )
            self.index = i
            return self.cache[n], n, i, #imageList, self.cache.n, self.cache_size
        end,

        getNext = function(self)
            if(self.index==#imageList)then self.index=0 end
            return self:get(self.index+1)
        end,

        getPrev = function(self)
            if(self.index==1)then self.index=#imageList+1 end
            return self:get(self.index-1)
        end,

        clear = function(self, rev)
            if(self.cache_size>0) and (self.cache.n>self.cache_size)then
                if(self.spreload>0)then
                    local img = {}
                    local a = rev and (self.index-self.spreload) or self.index
                    local b = rev and self.index or (self.index+self.spreload)
                    for i=a, b do
                        local i = (i<=0) and ((#imageList+1+i) or i) or (i>#imageList) and (#imageList-1-i) or i
                        local n = imageList[i] or "nil"
                        img[n] = self.cache[n]
                    end
                    self.cache = setmetatable({ n = 0, a=nil, b=nil, c=nil, d=nil, e=nil }, 
                    { __newindex = function(self, k, v)
                        self.n = v and (self.n+1) or self.n
                        rawset(self,k,v)
                    end })
                    for k,v in next, img do
                        self.cache[k] = v
                    end
                    self:softpreload(rev)
                    img = nil
                    --collectgarbage()
                    --print("GC'd (with preload)")
                else
                    self.cache = setmetatable({ n = 0, a=nil, b=nil, c=nil, d=nil, e=nil }, 
                    { __newindex = function(self, k, v) 
                        self.n = v and (self.n+1) or self.n
                        rawset(self,k,v)
                    end })
                    --collectgarbage()
                end
            elseif(self.spreload>0) then self:softpreload(rev)
            end
        end,

        softpreload = function(self, rev)
            if(self.spreload>0)then
                local a = rev and (self.index-self.spreload) or self.index
                local b = rev and self.index or (self.index+self.spreload)
                for i=a, b do
                    local i = (i<=0) and ((#imageList+1+i) or i) or (i>#imageList) and (#imageList-1-i) or i
                    self:add(i)
                end
            end
        end,

        preload = function(self)
            for i=1, #imageList do
                self:add( i )
            end
        end,

        close = function(self)
            -- do something if required
            -- arch:close(), ...
        end
    }
end

local rel_pos = function(p, r, c)
    local t = setmetatable({
        left   = nil,
        right  = nil,
        top    = nil,
        bottom = nil,
        intern = nil,
        extern = nil,
    }, { __tostring = function(self)
        return string.format("%s, %s, %s", self.left or self.right, 
        self.bottom or self.top,
        self.intern or self.extern)
    end})
    t[p] = p
    t[r] = r
    t[c] = c
    return t
end

local function relative_pos(ba, xb, yb)
    local ap = luce.Point(luce.Rectangle(ba):getCentre())
    local mp = luce.Point{xb, yb}
    local nx, ny = unpack((mp-ap):dump())
    local hx, hy = ap.x/2, ap.y/2
    local p = nx<0 and "left" or "right"
    local r = ny<0 and "top" or "bottom"
    local c = ((math.abs(nx) < hx) and (math.abs(ny) < hy)) and "intern" or "extern"
    return rel_pos(p, r, c)
end


local function new(_, name)
    local name        = name or componentName
    local comp        = luce:ImageComponent(name)

    local topComp     = nil
    local appName     = nil
    local textColour  = luce:Colour(luce.Colours.red)
    local image_info  = image_info
    local image_cache = image_cache
    local relative_pos= relative_pos
    local imageCache  = nil
    local bookTitle   = nil

    local noNotif = luce.NotificationType.dontSendNotification
    local slider      = luce:Slider("sliderNavigation")
    slider:setRange(1, 1, 1)
    slider.visible = false
    comp:addChildComponent(slider)

    local self        = { -- init self with pre-defined rooms
        showing       = false,
        book          = nil,
        info          = nil,
        setBook       = nil,
        showInfo      = nil,
        setImage      = nil,
        setBounds     = nil,
        image         = nil,
    }

    ---
    -- image size control
    ---
    local fit_width   = false
    local fit_height  = true
    local zoom_factor = 1
    local zoom_step   = 0.1
    local function set_bounds(bounds, zoom_update)
        local bounds = luce:Rectangle(bounds or {0, 0, comp:getParentWidth(), comp:getParentHeight()})
        --if not(comp:isShowing())then return end
        local r = luce:Rectangle(bounds)
        if(fit_width)then
            r.h = r.w * self.info.ratio
        elseif (zoom_factor==1) and not(fit_height) then
            fit_height = true
        elseif not(zoom_factor==1) and (zoom_update or fit_height) then
            fit_height = false
            r = r*zoom_factor
            --r.h = r.w * self.info.ratio
            comp:setBounds(r)
        end
        if(fit_height)then
            comp:setBounds(r)
        end
    end

    function self:setBounds(bounds)
        set_bounds(bounds)
    end

    function self:fitWidth(b)
        fit_width = b
        set_bounds()
    end

    function self:zoom(b)
        zoom_factor = b and (zoom_factor+zoom_step) or (zoom_factor-zoom_step)
        zoom_factor = (zoom_factor<=0) and 0.1 or zoom_factor
        set_bounds(nil, true)
    end

    function self:setZoom(b)
        if(b)then zoom_factor = 1.5
        else zoom_factor = 1 end
        set_bounds(nil, true)
    end

    comp:mouseDrag(function(mouseEvent)
    end)

    ---
    -- book management
    ---
    local function load_book(book, cached, preloaded, startIndex)
        if imageCache then
            imageCache:close()
        end
        local r, e = image_cache(book, cached, preloaded, startIndex)
        if not(r) then return r, e
        else
            imageCache = r
            slider:setRange(1, imageCache.total, 1)
            return true
        end
    end

    function self:setBook(book, cached, preloaded, startIndex)
        local r, e = load_book(book, cached, preloaded, startIndex)
        if not r then return nil, e end
        self:set(1)
        self.book = book
        bookTitle = book:gsub("^.*[/\\]([^/\\]+).*%.[^%.]+.*$","%1")
        return true , nil, luce:Point{self.info.width, self.info.height}, bookTitle
    end

    ---
    -- cheap eye candy effects (mainly to demonstrate we can get and set anything we want)
    ---
    local function update_title()
        if not self.book or not comp.visible then return end
        if not(topComp) then
            topComp = comp:getTopLevelComponent()
            appName = topComp:getName()
        end
        local index, imageName = imageCache:current()
        local title = string.format("%s | %s - %s (%s/%s)",
                appName,
                bookTitle, 
                imageName:gsub("^.*[/\\]([^/\\]+).*%.[^%.]+.*$","%1"), 
                index, 
                imageCache.total
        )
        topComp:setName( title )
    end

    local function update_slider()
        if (slider.visible) then
            slider:setValue( imageCache.index, noNotif )
        end
    end

    ---
    -- navigation functions
    ---
    local function set_image(image, ...)
        self.info = image_info(image, ...)
        comp:setImage(image)
        update_slider(imageCache.index)
        update_title()
    end

    -- get and display next image
    function self:next()
        set_image( imageCache:getNext() )
    end

    -- get and display previous image
    function self:previous()
        set_image( imageCache:getPrev() )
    end

    -- get and display image at given index
    function self:set(index)
        set_image( imageCache:get(index) )
    end

    function self:showInfo(b)
        if ( b == self.showing ) then return end
        if (self.info) then
            self.showing = b
            comp:repaint()
        end
    end
    
    ---
    -- navigation events
    ---
    local K = string.byte
    local kc = setmetatable( luce.KeyPress.KeyCodes, { __index = function()return 0 end })
    function self:userKeyEvent(k, m)
        if (k == kc.spaceKey or k == kc.rightKey) then
            self:next()

        elseif (k == kc.leftKey or k == kc.backspaceKey) then
            self:previous()

        elseif (k == kc.homeKey) then
            self:set(1)

        elseif (k == kc.endKey) then
            self:set(imageCache.total)

        elseif (k==K"I" or k==K"i") then
            self:showInfo( not(self.showing) )

        elseif (k==K"S" or k==K"s") then
            slider.visible = not(slider.visible)
            if(slider.visible) then update_slider() end
            comp:repaint()

        elseif (k==K"w" or k==K"W") then
            self:fitWidth( not(fit_width) )

        elseif (k==K"z" or k==K"Z") then
            self:setZoom( zoom_factor==1 )

        elseif (k==K"+") then
            self:zoom(true)

        elseif (k==K"-" or k==173) then
            self:zoom(false)
            
        else
            return false -- don't consume key
        end
        return true -- consume key
    end

    comp:mouseDown(function(me)
        -- FIXME: get real image bounds or compute real image centre point instead of using window bounds
        local p = relative_pos(comp:getLocalBounds(), me:getMouseDownX(), me:getMouseDownY())
        if (p.intern) then
            slider.visible = not(slider.visible)
            comp:repaint()
        else
            (me.mods.isLeftButtonDown() and p.right and self.next or self.previous)()
        end
    end)

    comp:mouseWheelMove(function(me, wheel)
        ((wheel.deltaY > 0 ) and self.next or self.previous)()
    end)

    slider:stoppedDragging(function()
        self:set( slider.value )
    end)

    -- TODO:
    -- self:rotate(dir)
    -- self:fitWidth()
    -- self:fitHeight()
    -- ...
    -- use a viewport ?

    comp:paint(function(g)
        if(slider.visible)then
            local r = luce:Rectangle(comp:getBounds())
            local sr = r:withTop(r:getHeight() - 30)
            slider:setBounds( sr )
        end

        if not(self.showing) then return end
        if(self.image) and not(self.image:isNull())then
            local f = g:getCurrentFont()
            local h = f:getHeight()
            do
                local state = g:ScopedSaveState()
                g:setColour(textColour)
                local maxw = comp:getWidth()
                local fn = self.info.filename
                local w1 = math.min(f:getStringWidth(fn), maxw)
                g:drawText(fn, 10, 10, w1, h, luce.JustificationType.left, true)
                local index = self.info.position .. "/" .. self.info.total
                local w2 = math.min(f:getStringWidth(index), maxw)
                g:drawText(index, 10, 10+h+2, w2, h, luce.JustificationType.left, true)
            end
        end
    end)

    self.__self = comp.__self
    return setmetatable(self, {
        __tostring = function()return name end,
        __self     = comp.__self,
        __index    = comp,
        __newindex = comp,
    })
end

return setmetatable({}, {
    __tostring = function()return componentName end,
    __call = new
})
