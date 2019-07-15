--[[
* The MIT License
* Copyright (C) 2012 Matthew Smith <matthew@rapidfirestudio.com>.  
* All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

require "pubnub"
local json = require("dkjson")

--
-- GET YOUR PUBNUB KEYS HERE:
-- http://www.pubnub.com/account#api-keys
--
pn = pubnub.new ( {
    	publish_key   = "demo",
	subscribe_key = "demo",
	secret_key    = nil,                -- YOUR SECRET KEY
	auth_key      = "",
	ssl           = false,
	origin        = "pubsub.pubnub.com" -- PUBNUB CLOUD ORIGIN
} )

--
-- PUBNUB PUBLISH MESSAGE (SEND A MESSAGE)
--
pn:publish ( {
	channel  = "hello_world",
	message  = { time=os.date("%X")},
	callback = function ( info )

		-- WAS MESSAGE DELIVERED?
		if info[1] then
			print ( "MESSAGE DELIVERED SUCCESSFULLY!" )
		else
			print ( "MESSAGE FAILED BECAUSE -> " .. info[2] )
		end

	end
} )

--
-- PUBNUB SUBSCRIBE CHANNEL (RECEIVE MESSAGES)
--
pn:subscribe ( {
	channel  = "hello_world",
	callback = function ( message , ch)
		-- MESSAGE RECEIVED!!!
		print ( ch .. " : " .. ( json.encode(message) ) )
		--[[
		pn:subscribe({
		channel = "a",
		callback = function(message, ch)
		print ( ch .. " : " .. ( MOAIJsonParser.encode ( message ) or message ) )
		end,
		presence = function(message, ch)
		print ( ch .. " : " .. ( MOAIJsonParser.encode ( message ) or message ) )
		end,

		})
		--]]
	end,
	error = function(err)
		print ( "error" )
	end,
	presence = function(message, ch) 
		print( "presence - " .. ch .. " : " .. ( json.encode(message) or message ) )
	end

} )

--[[
pn:subscribe ( {
channel  = "lua-5,lua-6,lua-7,lua-8,a",
callback = function ( message , ch)
-- MESSAGE RECEIVED!!!
print ( ch .. " : " .. ( MOAIJsonParser.encode ( message ) or message ) )
pn:unsubscribe({channel = "a"})
end,
error = function(err)
print ( "error" )
end,
presence = function(message, ch) 
print ( ch .. " : " .. ( MOAIJsonParser.encode ( message ) or message ) )
end

} )
--]]
--
-- PUBNUB UN-SUBSCRIBE CHANNEL (STOP RECEIVING MESSAGES)
--
--pn:unsubscribe ( {
--    channel = "lua-moai-demo-channel"
--} )

--
-- PUBNUB LOAD MESSAGE HISTORY
--
--pn:history ( {
--   channel  = "lua-moai-demo-channel",
--    limit    = 10,
--    callback = function ( messages )
--        if not messages then
--            return print ( "ERROR LOADING HISTORY" )
--        end
--
--        -- NO HISTORY?
--        if not ( #messages > 0 ) then
--            return print ( "NO HISTORY YET" )
--        end
--
--        -- LOOP THROUGH MESSAGE HISTORY
--        for i, message in ipairs ( messages ) do
--            print ( MOAIJsonParser.encode ( message ) )
--        end
--    end
--} )


--
-- PUBNUB SERVER TIME
--
pn:time ( function ( time )
        -- PRINT TIME
        print ( "PUBNUB SERVER TIME: " .. time )
    end
)

--
-- Message Counts
--
pn:message_counts({
      channels = { "hello_world", "test", "Zuvoin"},
      channelTimeTokens = { 5},
      callback = function(response)
	 print(json.encode(response))
      end,
      error = function(response)
	 print("error:" .. json.encode(response))
      end
})

--
-- PUBNUB UUID
--
--uuid = pn:UUID ()
--print ( "PUBNUB UUID: ", uuid )
