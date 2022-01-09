local richText = require 'richText'

local str = richText[[
	<italic>So italian</italic>
]]

function love.draw()
	str:draw{
		scale = 2,
	}
end