--
-- PubNub : Presence Example
--
require "PubnubUtil"
require "pubnub"
require "table"

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

local textout = PubnubUtil.textout

-- 
-- STARTING WELCOME MESSAGE FOR THIS EXAMPLE
-- 
textout("...")
textout(" ")

-- 
-- HIDE STATUS BAR
-- 
display.setStatusBar( display.HiddenStatusBar )

-- 
-- FUNCTIONS USED FOR TEST
-- 
function presence( channel, donecb )
    pubnub_obj:subscribe({
        channel = channel,
        connect = function()
            textout('Connected to channel ')
            textout(channel)
        end,
        callback = function(message)
            for i,v in pairs(message) do textout(i .. " " .. v) end
            timer.performWithDelay( 500, donecb )
        end,
        presence = function(message)
            for i,v in pairs(message) do textout(i .. " " .. v) end
        end,
        errorback = function()
            textout("Oh no!!! Dropped 3G Conection!")
        end
    })
end

-- 
-- MAIN TEST
-- 
local my_channel = 'hello_world'
pubnub_obj:set_uuid('my-test-uuid')
presence(my_channel, function() end)
