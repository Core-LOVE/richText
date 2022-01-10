local t = {}
t.fontCache = {}
t.imgCache = {}

local hex

do
	local tn = function(str, f, s)
		return tonumber('0x' .. str:sub(f, s)) / 255
	end
	
	hex = function(str)
		local r = tn(str, 1, 2)
		local g = tn(str, 3, 4)
		local b = tn(str, 5, 6)
		local a = 1
		
		if #str ~= 6 then
			a = tn(str, 7, 8)
		end
		
		return {r, g, b, a}
	end
	
	t['alpha'] = function(settings, val)
		settings.color[4] = val
	end
	
	t['opacity'] = t['alpha']
	
	local function makeColor(n, t)
		return function(settings)
			settings.color = t
		end
	end
	
	t['red'] = makeColor('red', {1, 0, 0, 1})
	t['green'] = makeColor('green', {0, 1, 0, 1})
	t['blue'] = makeColor('blue', {0, 0, 1, 1})
	t['purple'] = makeColor('purple', {0.5, 0, 1, 1})
	t['pink'] = makeColor('pink', {1, 0, 1, 1})
	t['yellow'] = makeColor('yellow', {1, 1, 0, 1})
	t['aqua'] = makeColor('aqua', {1, 1, 0, 1})
	t['black'] = makeColor('black', {0, 0, 0, 1})
	
	local abs = math.abs
	
	local fromHSV = function(h, s, v, a)
		h = h*6;  -- 6 = 360/60
		local c = v*s;
		local x = c*(1-abs(h%2 - 1));
		local r,g,b = 0,0,0;
		
		if(h <= 1) then
			r = c;
			g = x;
		elseif(h <= 2) then
			r = x;
			g = c;
		elseif(h <= 3) then
			g = c;
			b = x;
		elseif(h <= 4) then
			g = x;
			b = c;
		elseif(h <= 5) then
			r = x;
			b = c;
		else
			r = c;
			b = x;
		end
		local m = v - c;
		return {r+m,g+m,b+m,a};
	end
	
	t['rainbow'] = function(settings, val)
		local val = val 
		local x = settings.count * 0.1
		
		if type(val) == 'boolean' then
			val = 1
		end
		
		local t = (love.timer.getTime() + x) * 0.75 * val
		
		settings.color = fromHSV(t % 1, 1, 1, 1)
	end
	
	t['color'] = function(settings, val)
		if t[val] then
			t[val](settings)
		else
			settings.color = hex(val)
		end
	end
end

t['scaleX'] = function(settings, val)
	settings.scale[1] = val
end

t['scaleY'] = function(settings, val)
	settings.scale[2] = val
end

t['scale'] = function(settings, val)
	settings.scale = {val, val}
end

local random = math.random

t['shake'] = function(settings, val)
	settings.offset[1] = random(-val, val)
	settings.offset[2] = random(-val, val)
end

local rad = math.rad

t['rotation'] = function(settings, val)
	settings.rotation = rad(val)
end

t['rotationSpeed'] = function(settings, val)
	local time = love.timer.getTime() * val
	
	settings.rotation = rad(time)
end

local cos = math.cos

t['wave'] = function(settings, val)
	local val = val 

	if type(val) == 'boolean' then
		val = 1
	end
	
	local x = settings.count * 0.1
	local time = love.timer.getTime() + x
	
	settings.offset[2] = cos(time * val) * 2
end

t['italic'] = function(settings, val)
	if type(val) == 'boolean' then
		val = -0.25
	end
	
	settings.shearing[1] = val
end

t['shadow'] = function(settings, val)
	local val = val
	
	if type(val) == 'boolean' then
		val = nil
	end
	
	settings.shadow = (val and hex(val)) or {0, 0, 0, 1} 
end

t['image'] = function(settings, val)
	if not t.imgCache[val] then
		t.imgCache[val] = love.graphics.newImage(val)
	end
	
	local x = settings.pos[1]
	local y = settings.pos[2]
	
	love.graphics.draw(t.imgCache[val], x, y)
end

t['img'] = t['image']
t['texture'] = t['texture']

t['icon'] = function(settings, val)
	if not t.imgCache[val] then
		t.imgCache[val] = love.graphics.newImage(val)
	end
	
	local x = settings.pos[1]
	local y = settings.pos[2]
	
	local char = settings.char
	local font = settings.font
	local texture = t.imgCache[val]
	local scale = settings.scale
	
	local w = font:getWidth(char)
	local h = font:getHeight(char)
	local scaleX = (w / texture:getWidth()) * scale[1]
	local scaleY = (h / texture:getHeight()) * scale[2]
	
	love.graphics.draw(t.imgCache[val], x, y, 0, scaleX, scaleY)
end

t['underline'] = function(settings)
	local font = settings.font
	local char = settings.char
	local scale = settings.scale
	
	local x = settings.pos[1]
	local y = settings.pos[2] + font:getHeight(char) * scale[2]
	local x2 = x + (font:getWidth(char) * scale[1])
	local y2 = y
	
	love.graphics.push()
		love.graphics.setLineWidth(scale[2])
		love.graphics.setLineStyle('rough')
		love.graphics.line(x, y, x2, y2)
	love.graphics.pop()
end

t['strikeout'] = function(settings)
	local font = settings.font
	local char = settings.char
	local scale = settings.scale
	
	local x = settings.pos[1]
	local y = settings.pos[2] + (font:getHeight(char) * scale[2]) * 0.5
	local x2 = x + (font:getWidth(char) * scale[1])
	local y2 = y
	
	love.graphics.push()
		love.graphics.setLineWidth(scale[2])
		love.graphics.setLineStyle('rough')
		love.graphics.line(x, y, x2, y2)
	love.graphics.pop()
end

t['strike'] = t['strikeout']

t['br'] = function(settings)
	settings.char = "\n"
end

t['break'] = t['br']

t['greater'] = function(settings)
	settings.char = ">"
end

t['less'] = function(settings)
	settings.char = "<"
end

t['gt'] = t['greater']
t['lt'] = t['less']

return t