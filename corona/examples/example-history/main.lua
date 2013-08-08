--
-- PubNub 3.3 : History Example
--

require "pubnub"
require "PubnubUtil"

textout = PubnubUtil.textout

--
-- INITIALIZE PUBNUB STATE
--
pubnub_obj = pubnub.new({
    publish_key   = "demo",
    subscribe_key = "demo",
    secret_key    = nil,
    ssl           = nil,
    origin        = "pubsub.pubnub.com"
})

-- 
-- HIDE STATUS BAR
-- 
display.setStatusBar( display.HiddenStatusBar )

-- 
-- CALL HISTORY FUNCTION
--
function history(channel, count, reverse)
    pubnub_obj:history({
        channel = channel,
        count = count,
        reverse = reverse,
        callback = function(response)
            textout(response)
        end,
        error = function (response)
            textout(response)
        end
    })
end

-- 
-- MAIN TEST
-- 
local my_channel = 'hello_world'
history( my_channel, 5, false )
