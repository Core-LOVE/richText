local richText = {
	_NAME = "richText",
	_VERSION = '1.0',
	_DESCRIPTION = "Custom text drawing/parsing in Love2d with tags and stuff.",
	
	_URL = 'https://github.com/Core-LOVE/richText',
	
	_LICENSE = 'MIT license',
}

local convert
local cache = {}

local utf8 = require 'utf8'

local tags = {}

function richText.addTag(name, f)
	tags[name] = f
end

function richText.getTag(name)
	return tags[name]
end

-- default tags loading
do
	local name = ...
	name = name .. "/tags"
	
	local t = require(name)
	
	for k,v in pairs(t) do
		if type(v) == 'function' then
			richText.addTag(k, v)
		end
	end
end

do
	local function utf8sub(s,i,j)
		i=utf8.offset(s,i)
		j=utf8.offset(s,j+1)-1
		return string.sub(s,i,j)
	end

	local function copy(t)
		local t2 = {}
		
		for k,v in pairs(t) do
			t2[k] = v
		end
		
		return t2
	end

	convert = function(str)
		local newStr = {}
		local strTags = {}
		
		local currentTag = ""
		local currentTagVal = true
		
		local parseTagVal = false
		local parseTag = false
	
		for k = 1, utf8.len(str) do
			local character = utf8sub(str, k, k)
			
			if parseTag and character ~= [[>]] then
				if parseTagVal then
					currentTagVal = currentTagVal .. character
				else
					if character ~= [[=]] and character ~= [[/]] then
						currentTag = currentTag .. character
					end
				end
				
				if character == [[=]] then
					currentTagVal = ""
					parseTagVal = true
				end
			end
		
			if character == [[<]] and not parseTag then
				parseTag = true
			end
		
			if not parseTag then
				newStr[#newStr + 1] = {char = character, tags = copy(strTags)}
			end
			
			if character == [[>]] then
				parseTag = false
				parseTagVal = false
				
				if not strTags[currentTag] then
					strTags[currentTag] = currentTagVal
				else
					strTags[currentTag] = nil
				end
				
				currentTag = ""
				currentTagVal = true
			end
		end
		
		return newStr
	end
end

setmetatable(cache, {__call = function(self, text)
	if rawget(cache, text) == nil then
		rawset(cache, text, convert(text))
	end
	
	return rawget(cache, text)
end})

function richText.convert(str)
	return (type(str) == 'string' and cache(str)) or str
end

function richText.len(str)
	return #str.text
end

richText.metatable = {__index = richText,
	__len = function(str) -- If it doesn't work (100% related to version older than 5.2) use richTextString:len() instead
		return #str.text
	end,
	
	__concat = function(a, b)
		if type(b) == 'number' then
			b = tostring(b)
		end
		
		if type(b) == 'string' then
			b = richText.convert(b)
		end

		if type(b) == 'table' then
			for i = 1, #b do
				a.text[#a.text + 1] = b[i]
			end
		end
		
		-- for i = 1, #a.text do
			-- print(i, a.text[i])
		-- end
		
		return a
	end,
	
	__tostring = function(t)
		local str = ""
		
		for i = 1, #t.text do
			str = str .. t.text[i].char
		end
		
		return str
	end,
}

function richText.new(str)
	local v = {}
	
	v.text = richText.convert(str)
	v.len = richText.len
	v.__type = "richText"
	
	setmetatable(v, richText.metatable)
	return v
end

local defaultFont = love.graphics.getFont( )

function richText:draw(args)
	local v = self
	
	if type(v) == 'string' then
		v = richText.convert(v)
	end
	
	local args = args or {}
	
	local startX = args.x or 0
	local startY = args.y or 0

    local x = startX
	local y = startY
	
	local prevchar = ""
	
	
		-- love.graphics.rotate(math.rad(v.rotation))
		-- love.graphics.translate(-v.alignX, -v.alignY)
    for i,v in ipairs(v.text) do
		local parent = v
		local tags = v.tags
		local v = v.char
		
		-- settings stuff
		local settings = {}
		
		settings.parent = parent
		settings.char = v
		
		settings.offset = {0, 0}
		settings.pos = {x, y}
		
		settings.color = args.color or {1,1,1,1}
		settings.scale = {1, 1}
		
		if args.scaleX or args.scaleY then
			settings.scale = {args.scaleX or 1, args.scaleY or 1}
		end
		
		if args.scale then
			if type(args.scale) == 'number' then
				settings.scale = {args.scale, args.scale}
			else
				settings.scale = args.scale
			end
		end
		
		settings.shearing = {0, 0}
		
		settings.font = args.font or defaultFont
		settings.rotation = 0
		
		--tags
		do
			for k,v in pairs(tags) do
				local tag = richText.getTag(k)
				
				if tag ~= nil then
					tag(settings, v)
				end
			end
		end
		--]]
		
		local font = settings.font
		
        local width = font:getWidth(v)
        local kerning = (prevchar == "" and 0) or font:getKerning(prevchar, v)
		
		--rendering
		love.graphics.push()
			love.graphics.setColor(settings.color)
			love.graphics.print(v, 
				x + kerning + settings.offset[1], y + settings.offset[2], 
				settings.rotation, 
				settings.scale[1], settings.scale[2],
				0, 0,
				settings.shearing[1], settings.shearing[2]
			)
		love.graphics.pop()
		--]]
		
        prevchar = v
        x = x + ((kerning + width) * settings.scale[1])
		
		if v:find('\n') then
			y = y + font:getHeight() * settings.scale[2]
			x = 0
		end
    end
end

setmetatable(richText, {__call = function(self, ...)
	return self.new(...)
end})

return richText