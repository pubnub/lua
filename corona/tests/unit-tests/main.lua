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

local total = 1 + 2 + 2 + 20 + 2
local pass = 0
local fail = 0

local function test(condition, name, description)
    if (condition) then
        pass = pass + 1
        print('PASS : ' .. name .. " : " ..description)
    else
        fail = fail + 1
        print('FAIL : ' .. name .. " : " ..description)
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
                    test(r[1] == 1, name, "Message should get published")
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
                    test(r == msg, name, "Message published should be received")
                end,
                connect = function(c)
                    pubnub_obj:publish({
                        channel = ch,
                        message = msg,
                        callback = function(r)
                            test(r[1] == 1, name, "Message should get published")
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
                        name, "Message published should be received")
                        pubnub_obj:unsubscribe({channel = ch})
                end,
                connect = function(c)
                    pubnub_obj:publish({
                        channel = ch,
                        message = msg,
                        callback = function(r)
                            test(r[1] == 1, name, "Message should get published")
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
                        test(p.occupancy == 1, name, "Test Occupancy 1")
                        count = count + 1
                    else 
                        test(p.occupancy == 2, name, "Test Occupancy 2")
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
    },
    {
        
        func = 
        function()
            name = "History Test"
            local msg = "hi"
            local ch = channel .. "5"
            pubnub_obj:publish({
                channel = ch,
                message = msg,
                callback = function(r)
                    test(r[1] == 1, name, "Message should get published")
                    pubnub_obj:history({
                        channel = ch,
                        count = 1,
                        callback = function(r)
                            test(r[1][1] == msg, name, "Message published should be available in history")
                            test(r[1][2] == nil, name, "History Message count")
                        end
                    })
                end,
                error = function(e)
                end
            })
        end
    },
    {
        
        func = 
        function()
            name = "History Test with 2 Published messages"
            local msg1 = 1
            local msg2 = 2
            local ch = channel .. "6"
            pubnub_obj:publish({
                channel = ch,
                message = msg1,
                callback = function(r)
                    test(r[1] == 1, name, "Message should get published")
                    pubnub_obj:publish({
                        channel = ch,
                        message = msg2,
                        callback = function(r)
                            test(r[1] == 1, name, "Message should get published")
                            timer.performWithDelay(5000, function()
                                pubnub_obj:history({
                                    channel = ch,
                                    count = 1,
                                    callback = function(r)
                                        test(r[1][1] == msg2, name, "Message published should be available in history 1")
                                        test(r[1][2] == nil, name, "History Message count")
                                    end
                                })
                                pubnub_obj:history({
                                    channel = ch,
                                    callback = function(r)
                                        test(r[1][1] == msg1, name, "Message published should be available in history 2")
                                        test(r[1][2] == msg2, name, "Message published should be available in history 3")
                                        test(r[1][3] == nil, name, "Message Count 2")
                                    end
                                })
                            end)
                        end,
                        error = function(e)
                        end
                    })
                    
                end,
                error = function(e)
                end
            })
        end
    },
        {
        
        func = 
        function()
            name = "History Test with 2 Published messages with reverse true"
            local msg1 = 1
            local msg2 = 2
            local ch = channel .. "7"
            pubnub_obj:publish({
                channel = ch,
                message = msg1,
                callback = function(r)
                    test(r[1] == 1, name, "Message should get published")
                    pubnub_obj:publish({
                        channel = ch,
                        message = msg2,
                        callback = function(r)
                            test(r[1] == 1, name, "Message should get published")
                            timer.performWithDelay(5000, function()
                                pubnub_obj:history({
                                    channel = ch,
                                    count = 1,
                                    reverse = true,
                                    callback = function(r)
                                        test(r[1][1] == msg1, name, "Message published should be available in history 1")
                                        test(r[1][2] == nil, name, "History Message count")
                                    end
                                })
                                pubnub_obj:history({
                                    channel = ch,
                                    reverse = true,
                                    callback = function(r)
                                        test(r[1][1] == msg1, name, "Message published should be available in history 2")
                                        test(r[1][2] == msg2, name, "Message published should be available in history 3")
                                        test(r[1][3] == nil, name, "Message Count 2")
                                    end
                                })
                            end)
                        end,
                        error = function(e)
                        end
                    })
                    
                end,
                error = function(e)
                end
            })
        end
    },
    {
        
        func = 
        function()
            local name = "Here Now Test"
            local ch = channel .. "8"
            local msg = {1,2,3}
            local count = 0
            local pubnub_obj_2
            pubnub_obj:subscribe({
                channel = ch,
                callback = function(r) end,
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
                            connect = function(r)
                                timer.performWithDelay(5000, function()
                                    pubnub_obj:here_now({
                                        channel = ch,
                                        callback = function(r)
                                            test(r.occupancy == 2, name, "Here Now occupancy test")
                                        end
                                    })
                                end)
                            end,
                            callback = function() end
                            
                        })
                    end)
                end

            })
        end
    },
    {
        
        func = 
        function()
            local name = "Unsubscribe should decrease occupancy Test"
            local ch = channel .. "9"
            local msg = {1,2,3}
            local count = 0
            local pubnub_obj_2
            pubnub_obj:subscribe({
                channel = ch,
                callback = function(r) end,
                connect = function(c)
                    timer.performWithDelay(3000, function()
                        pubnub_obj:here_now({
                            channel = ch,
                            callback = function(r)
                                test(r.occupancy == 1, name, "Subcribe should increase occupancy by one")
                                pubnub_obj:unsubscribe({channel = ch})
                                timer.performWithDelay(15000, function()
                                    pubnub_obj:here_now({
                                        channel = ch,
                                        callback = function(r)
                                            test(r.occupancy == 0, name, "Unsubcribe should decrease occupancy by one")
                                        end
                                    })
                                end)
                            end,
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

