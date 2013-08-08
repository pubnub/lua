--
-- PubNub 3.1 : Here Now Example
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
-- CALL HERE NOW FUNCTION
--
function here_now(channel)
    pubnub_obj:here_now({
        channel = channel,
        limit = limit,
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
local my_channel = 'hello-corona-demo-channel'
here_now( my_channel )
