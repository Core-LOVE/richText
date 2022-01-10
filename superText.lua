local superText = {
	_NAME = "superText",
	_VERSION = '1.0',
	_DESCRIPTION = "Custom text drawing/parsing in Love2d with tags and stuff.",
	
	_URL = 'https://github.com/Core-LOVE/superText',
	
	_LICENSE = 'MIT license',
}

local utf8 = require 'utf8'

local tags = {}

function superText.addTag(name, f)
	tags[name] = f
end

function superText.getTag(name)
	return tags[name]
end

-- default tags loading
do
	local name = ...
	name = name .. "/tags"
	
	local t = require(name)
	
	for k,v in pairs(t) do
		if type(v) == 'function' then
			superText.addTag(k, v)
		end
	end
end

local convert

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

function superText.convert(str)
	return convert(str)
end

function superText.len(str)
	return #str.text
end

superText.metatable = {__index = superText,
	__len = function(str) -- If it doesn't work (100% related to version older than 5.2) use superTextString:len() instead
		return #str.text
	end,
	
	__concat = function(a, b)
		local str = ""
		
		if type(b) == 'number' then
			b = tostring(b)
		end
		
		if type(b) == 'string' then
			str = b
			b = superText.convert(b)
		end

		if type(b) == 'table' then
			for i = 1, #b do
				a.text[#a.text + 1] = b[i]
			end
		end
		
		-- for i = 1, #a.text do
			-- print(i, a.text[i])
		-- end
		
		a.originalText = a.originalText .. str
		return a
	end,
	
	__tostring = function(t)
		local str = ""
		
		for i = 1, #t.text do
			str = str .. t.text[i].char
		end
		
		return str
	end,
	
	__add = function(a, b)
		return a .. b
	end,
	
	__sub = function(a,b)
		a.originalText = a.originalText:gsub(b, "")
		return superText.convert(a.originalText)
	end,
	
	__mul = function(a,b)
		a.originalText = a.originalText:rep(b)
		return superText.convert(a.originalText)
	end,
	
	__eq = function(a,b)
		if type(b) == 'table' and b.__type == "superText" then
			return (a.originalText == b.originalText)
		end
	end,
}

function superText.new(str)
	local v = {}
	
	v.originalText = str
	v.text = superText.convert(str)
	v.len = superText.len
	v.__type = "superText"

	setmetatable(v, superText.metatable)
	return v
end

do
	local defaultFont = love.graphics.getFont( )

	local lprint = love.graphics.print
	local lpush = love.graphics.push
	local lpop = love.graphics.pop
	local lsetColor = love.graphics.setColor
	local ltranslate = love.graphics.translate
	local lrotate = love.graphics.rotate

	local getTag = superText.getTag
	local stConvert = superText.convert

	local rad = math.rad
	local find = string.find

	local aligning = {
		right	= 1,
		center  = 0.5,
	}

	aligning.centre = aligning.center

	function superText:render(args)
		local v = self
		
		if type(v) == 'string' then
			v = stConvert(v)
		end
		
		local args = args or {}
		
		local startX = args.x or 0
		local startY = args.y or 0

		local x = 0
		local y = 0
		
		local prevchar = ""
		local limit = args.maxCharacters or args.max
		
		if limit == nil or limit < 0 or limit > #v.text then
			limit = #v.text
		end
		
		local wrapLimit = args.wrapLimit or args.limit or 0
		
		local originX = args.originX or args.origin or 0
		local originY = args.originY or args.origin or 0
		local rot = args.rotation
		
		if rot then
			rot = rad(rot)
		end
		
		local align = args.align
		
		if align ~= nil and align ~= "left" then
			if wrapLimit <= 0 then 
				return error 'Wrap limit is required for aligning.'
			end
			
			align = aligning[align]
		else
			align = 0
		end

		lpush()

		ltranslate(startX + originX, startY + originY)
		lrotate(rot or 0)

		for i = 1, limit do
			local v = v.text[i]
			
			local parent = v
			local tags = v.tags
			local v = v.char
			
			-- settings stuff
			local settings = {}
			
			settings.args = args
			settings.self = self
			settings.parent = parent
			settings.char = v
			settings.count = i
			
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
			settings.shadow = args.shadow or false
			
			settings.font = args.font or defaultFont
			settings.rotation = 0
			
			--tags
			do
				for k,v in pairs(tags) do
					local tag = getTag(k)
					
					if tag ~= nil then
						tag(settings, v)
					end
				end
			end
			--]]
			
			local font = settings.font
			local char = settings.char
			
			local rotation = settings.rotation
			local scale = settings.scale
			local scaleX = scale[1]
			local scaleY = scale[2]
			
			local shearing = settings.shearing
			local shearingX = shearing[1]
			local shearingY = shearing[2]
			
			local offset = settings.offset
			local offsetX = offset[1]
			local offsetY = offset[2]
			
			local shadow = settings.shadow
			
			local kerning = (prevchar == "" and 0) or font:getKerning(prevchar, v)
			local width = (kerning + font:getWidth(v)) * scaleX
			
			--rendering
			
			lpush()
				local charX = (x + kerning + offsetX)
 				local charY = (y + offsetY)
				
				ltranslate(-originX, -originY)
				
				if shadow then
					lsetColor(shadow)
					
					lprint(char, 
						charX + 1, charY + 1, 
						rotation, 
						scaleX, scaleY,
						0, 0,
						shearingX, shearingY
					)
				end
				
				lsetColor(settings.color)
				
				lprint(settings.char, 
					charX, charY, 
					rotation, 
					scaleX, scaleY,
					0, 0,
					shearingX, shearingY
				)
			lpop()
			
			--]]
			
			prevchar = char
			
			x = x + width
			
			if find(char, '\n') or (wrapLimit > 0 and (x > wrapLimit or x < 0) ) then
				y = y + (font:getHeight() + font:getLineHeight()) * scaleY
				x = 0
			end
		end

		lpop()
		lsetColor(1, 1, 1, 1)
	end
end

superText.draw = superText.render

setmetatable(superText, {__call = function(self, ...)
	return self.new(...)
end})

return superText