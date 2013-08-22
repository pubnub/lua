--
-- PubNub : Unit tests
--
require "pubnub"
require "crypto"
require "PubnubUtil"

-- INITIALIZE PUBNUB STATE
--
local pubnub_obj = pubnub.new({
    publish_key   = "demo",
    subscribe_key = "demo",
    secret_key    = "demo",
    ssl           = false,
    origin        = "pubsub.pubnub.com"
})

local channel = "corona-lua-test-" .. math.random() .. "-"

local total = 7
local pass = 0
local fail = 0

local function test(condition,description)
    if (condition) then
        pass = pass + 1
        print('PASS : ' .. description)
    else
        fail = fail + 1
        print('FAIL : ' .. description)
    end
end


local tests = {
    
    {
        
        func = 
        function()
            name = "Publish Test"
            local msg = "hi"
            pubnub_obj:publish({
                channel = channel .. "1",
                message = msg,
                callback = function(r)
                    test(r[1] == 1, name .. " : " .. "Message should get published")
                end,
                error = function(e)
                end
            })
        end
    },
    {
        
        func = 
        function()
            local name = "Subscribe/Publish Test"
            local ch = channel .. "2"
            local msg = "Hello from Pubnub"
            pubnub_obj:subscribe({
                channel = ch,
                callback = function(r)
                    test(r == msg, name .. " : " .."Message published should be received")
                end,
                connect = function(c)
                    pubnub_obj:publish({
                        channel = ch,
                        message = msg,
                        callback = function(r)
                            test(r[1] == 1, name .. " : " .. "Message should get published")
                        end,
                        error = function(e)
                        end
                    })
                end

            })
        end
    },
    {
        
        func = 
        function()
            local name = "Subscribe/Publish table Test"
            local ch = channel .. "3"
            local msg = {1,2,3}
            pubnub_obj:subscribe({
                channel = ch,
                callback = function(r)
                    test((r[1] == msg[1] and 
                        r[2] == msg[2] and
                        r[3] == msg[3] ), 
                        name .. " : " .."Message published should be received")
                        pubnub_obj:unsubscribe({channel = ch})
                end,
                connect = function(c)
                    pubnub_obj:publish({
                        channel = ch,
                        message = msg,
                        callback = function(r)
                            test(r[1] == 1, name .. " : " .. "Message should get published")
                        end,
                        error = function(e)
                        end
                    })
                end

            })
        end
    },
    {
        
        func = 
        function()
            local name = "Presence Test"
            local ch = channel .. "4"
            local msg = {1,2,3}
            local count = 0
            local pubnub_obj_2
            pubnub_obj:subscribe({
                channel = ch,
                callback = function(r)end,
                presence = function(p)
                    if (count == 0) then
                        test(p.occupancy == 1, name .. " : " .. "Test Occupancy 1")
                        count = count + 1
                    else 
                        test(p.occupancy == 2, name .. " : " .. "Test Occupancy 2")
                        pubnub_obj:unsubscribe({channel = ch})
                        pubnub_obj_2:unsubscribe({channel = ch})
                    end

                end,
                connect = function(c)
                    pubnub_obj_2 = pubnub.new({
                        publish_key   = "demo",
                        subscribe_key = "demo",
                        secret_key    = "demo",
                        ssl           = false,
                        origin        = "pubsub.pubnub.com"
                    })
                    timer.performWithDelay(5000, function()
                        pubnub_obj_2:subscribe({
                            channel = ch,
                            callback = function(r) end,
                        })
                    end)
                end

            })
        end
    }

}


local function run_tests(test_table)
    for k,v in next, test_table do
        v.func()
    end
end

local timeout = 60
local i = 5

local function check_status()
    if ( pass + fail < total and i <= timeout) then
        timer.performWithDelay( i * 1000, check_status)
        i = i + 5
    else
        print("===== RESULTS ======")
        print("Total\t: " .. total)
        print('Pass\t: ' .. pass)
        print('FAIL\t: ' .. fail) 
        print('====================')
    end
end

run_tests(tests)
check_status()

