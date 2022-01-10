local richText = require 'superText'

local str = richText ""

local a = ""

local rot = 0

function love.draw()
	-- rot = rot + 8
	str:render{
		x = 16 + 400,
		y = 16,
		
		wrapLimit = 200,
		align = "center",
		
		rotation = rot,z
	}
	
	if love.keyboard.isDown 'z' then
		a = a .. "Hello"
		str = str .. "<rainbow>Hello</rainbow>"
	end
	
	love.graphics.printf(a, 8, 16, 200, 'center')	
end