--
-- PubNub : Publish Example
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
-- CALL PUBLISH FUNCTION
--
function publish(channel, text)
    pubnub_obj:publish({
        channel = channel,
        message = text,
        callback = function(r) textout("Publish response: " .. table.tostring(r)) 
        end,
        error = function(r) textout(r) 
        end
    })
end

-- 
-- MAIN TEST
-- 
local my_channel = 'lua-dsm'

--
-- Publish String
--
publish("abcd", 'Hello World!' )

--
-- Publish Dictionary Object
--
timer.performWithDelay(2000, function() publish("efgh", { Name = 'John', Age = '25' }) end)

--
-- Publish Array
--
timer.performWithDelay(4000, function() publish("ijkl", { 'Sunday', 'Monday', 'Tuesday' }) end)
