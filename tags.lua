local t = {}
t.fontCache = {}

t['color'] = function(settings, val)
	settings.color = {1, 0, 0, 1}
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

t['wave'] = function(settings, val)
	local w = settings.font:getWidth(settings.char) * settings.scale[1]
	local h = settings.font:getHeight(settings.char) * settings.scale[2]
	local time = (love.timer.getTime() / val + settings.scale[2]) / 2
	
	settings.offset[2] = math.sin(time * h + (settings.pos[1] / w)) * val
end

t['italic'] = function(settings, val)
	if type(val) == 'boolean' then
		val = -0.25
	end
	
	settings.shearing[1] = val
end

return t