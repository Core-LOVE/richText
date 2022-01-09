local richText = require 'richText'

local str = richText[[<italic>So italian</italic>]]

function love.draw()
	str:draw{
		x = 0,
	}
end