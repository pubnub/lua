--
-- PubNub : Subscribe Example
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
    ssl           = nil
})

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
function subscribe( channel )
    pubnub_obj:subscribe({
        channel = channel,
        connect = function()
            textout('Connected to channel ')
            textout(channel)
        end,
        callback = function(message)
            --print(message.data.message)
            textout(message)
        end,
        error = function()
            textout("Oh no!!! Dropped 3G Conection!")
        end,

    })
end

-- 
-- MAIN TEST
-- 

subscribe("lua-1")

