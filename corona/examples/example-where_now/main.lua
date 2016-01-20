--
-- PubNub : Here Now Example
--
require "pubnub"
require "PubnubUtil"

textout = PubnubUtil.textout

local my_uuid = 'corona-uuid'
local my_channel = 'corona-where-now-example-channel'
--
-- INITIALIZE PUBNUB STATE
--
pubnub_obj = pubnub.new({
    publish_key   = "demo",
    subscribe_key = "demo",
    secret_key    = nil,
    ssl           = nil,
    --uuid          = my_uuid,
    origin        = "pubsub.pubnub.com"
})

-- 
-- HIDE STATUS BAR
-- 
display.setStatusBar( display.HiddenStatusBar )

-- 
-- CALL HERE NOW FUNCTION
--
function where_now(uuid)
    pubnub_obj:where_now({
        uuid = uuid,
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


function subscribe(channel)
    pubnub_obj:subscribe({
        channel = channel,
        connect = function()
            textout('chan ' .. channel)
        end,
        callback = function(message)
           --print(message.data.message)
           --textout(message)
        end,
        error = function()
            textout("Oh no!!! Dropped 3G Conection!")
        end,
    })
end
subscribe(my_channel)

--here_now( my_channel )


timer.performWithDelay( 8000, function() --REPRO - run test multiple times
    where_now(my_uuid)
    textout(" ")
    textout(" ")
    textout("8 seconds passed, if occupancy = 0, error reproed")
end)

timer.performWithDelay( 16000, function() --REPRO - run test multiple times
    where_now(my_uuid)       
    textout(" ")
    textout(" ")
    textout("16 seconds passed, if occupancy = 0, error reproed")
end)

timer.performWithDelay( 16000, function() --REPRO - run test multiple times
    where_now()       
    textout(" ")
    textout(" ")
    textout("16 seconds passed, if occupancy = 0, error reproed")
end)

