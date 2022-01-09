local richText = require 'superText'

local str = richText[[<italic>Yep you got it right, it's italic text!</italic>
	<bold>And it's not like there is no way to bold your text up</bold>
]]

function love.draw()
	str:draw{
		x = 16,
		y = 16,
	}
end